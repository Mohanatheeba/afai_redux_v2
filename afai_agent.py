from typing import List, Dict, Any
from openai import OpenAI
import json
import os
from urllib.parse import urlparse

client = OpenAI()


def is_excel_source(meta: dict) -> bool:
    if meta.get("google_sheet_url"):
        return True
    if meta.get("sheet_name"):
        return True
    src = (meta.get("source_file") or "").lower()
    return src.endswith(".xlsx") or src.endswith(".xls")


def extract_filename_from_url(url: str) -> str:
    try:
        path = urlparse(url).path
        name = path.rstrip("/").split("/")[-1]
        return name or "file"
    except Exception:
        return "file"


def build_pdf_link_with_page(url: str, page: str | int | None) -> str:
    if not url:
        return "#"
    s = str(url)
    if ".pdf" in s.lower():
        try:
            pnum = int(page) if str(page).isdigit() else None
        except Exception:
            pnum = None
        if pnum:
            if "#" in s:
                return f"{s}&page={pnum}"
            elif "?" in s:
                return f"{s}&page={pnum}"
            else:
                return f"{s}#page={pnum}"
    return s


def get_custom_filename(metadata: dict) -> str:
    for key in ("filename", "title", "name"):
        if metadata.get(key):
            return str(metadata[key])
    return extract_filename_from_url(metadata.get("source_url", ""))


def contextualize_query(user_query, chat_history):
    try:
        messages = [
            {
                "role": "system",
                "content": (
                    "Given a chat history and the latest user query, which might reference context from previous messages, "
                    "formulate a standalone question that:\n"
                    "1. Captures the full contextual meaning of the original query\n"
                    "2. Can be understood independently without referencing the previous chat history\n"
                    "3. Preserves the original intent and specifics of the user's request\n"
                    "Do NOT answer the question. Just rewrite the query. "
                    "Remember to not pass Active Fire name if question is related to normal policies."
                )
            }
        ] + chat_history + [
            {
                "role": "user",
                "content": f"Rewrite this last question into a fully contextual standalone query:\n{user_query}"
            }
        ]

        response = client.chat.completions.create(
            model="gpt-4o-mini",
            messages=messages,
            temperature=0.7
        )

        return response.choices[0].message.content.strip()
    except Exception as e:
        print(f"[Error contextualizing query]: {e}")
        return user_query


def clarity_check(user_query: str, chat_history: list[dict[str, str]]) -> dict:
    new_chat_history = chat_history[-6:] if len(chat_history) > 6 else chat_history

    response_format = {
        "type": "json_schema",
        "json_schema": {
            "name": "clarity_check",
            "schema": {
                "type": "object",
                "properties": {
                    "clear": {
                        "type": "boolean",
                        "description": (
                            "True if the query is clear with specific project name and necessary details "
                            "(e.g., sheet name if relevant); False otherwise. "
                            "If the user mentions a project name not similar to AWPSGP2/SGP2/sgp2, "
                            "treat as unclear and mention no information is available for that project."
                        )
                    },
                    "clarification": {
                        "type": "string",
                        "description": (
                            "If not clear, a polite message asking the user for the missing details "
                            "(e.g., 'Could you specify the project name?'). Empty string if clear."
                        )
                    }
                },
                "required": ["clear", "clarification"],
                "additionalProperties": False
            }
        }
    }

    system_prompt = (
        "You are an assistant that evaluates if a user's query, in the context of chat history, "
        "is clear enough to answer. Specifically:\n"
        "- Check if the query or recent history explicitly mentions a project name.\n"
        "- If the query involves Excel sheets, check if a sheet name or row identifiers are provided when needed.\n"
        "- If the query is about general or multiple items without specification, it's not clear.\n"
        "- Common unclear cases: no project name when context suggests multiple projects; "
        "vague references to rooms, doors, slabs without identifiers.\n"
        "- If clear, set 'clear' to true and 'clarification' to empty string.\n"
        "- If unclear, set 'clear' to false and provide a direct, helpful clarification question.\n"
        "- Do not assume details; they must be explicitly stated in the query or history.\n"
        "- Return only the JSON object."
    )

    history_text = "\n".join([f"{msg['role']}: {msg['content']}" for msg in new_chat_history])

    messages = [
        {"role": "system", "content": system_prompt},
        {"role": "user", "content": f"Chat History:\n{history_text}\n\nUser Query: {user_query}"}
    ]

    response = client.chat.completions.create(
        model="gpt-4o",
        messages=messages,
        temperature=0.2,
        response_format=response_format
    )

    try:
        return json.loads(response.choices[0].message.content)
    except json.JSONDecodeError:
        return {"clear": True, "clarification": ""}


def project_specific_afai(
    user_query: str,
    vectorstore,
    chat_history: list[dict[str, str]],
    k: int = 3
) -> str:
    result = clarity_check(user_query, chat_history)
    if result["clear"]:
        return get_answer_with_sources(user_query, vectorstore, chat_history, k)
    return result["clarification"].strip()


def get_answer_with_sources(
    user_query: str,
    vectorstore,
    chat_history: list[dict[str, str]],
    k: int = 3
) -> str:
    k = 7

    enriched_query = contextualize_query(user_query, chat_history)
    docs = vectorstore.similarity_search(enriched_query, k=k)

    context_blocks = []
    available_sources = []

    for i, doc in enumerate(docs):
        meta = doc.metadata or {}

        source_url = meta.get("source_url") or meta.get("google_sheet_url") or "N/A"
        page       = meta.get("page", None)
        project    = meta.get("project_name") or meta.get("Project") or "N/A"
        sheet_name = meta.get("sheet_name") or ""
        row_start  = meta.get("row_start_1based")
        row_end    = meta.get("row_end_1based")
        title      = meta.get("title") or ""

        is_excel = is_excel_source(meta)
        if is_excel:
            display_label = "SGP2-AWP"
            link = source_url
            display_page = None
        else:
            display_label = get_custom_filename(meta) or extract_filename_from_url(source_url)
            link = build_pdf_link_with_page(source_url, page)
            display_page = page

        source_info = {
            "id": f"source_{i+1}",
            "is_excel": is_excel,
            "url": source_url,
            "link": link,
            "page": display_page,
            "display_label": display_label,
            "filename": display_label,
            "content": doc.page_content,
            "project_name": project,
            "sheet_name": sheet_name,
            "row_start_1based": row_start,
            "row_end_1based": row_end,
            "title": title,
        }
        available_sources.append(source_info)

        meta_lines = [
            f"Source ID: {source_info['id']}",
            f"Type: {'Excel' if is_excel else 'PDF/Other'}",
            f"URL: {source_url}",
        ]
        if not is_excel and display_page:
            meta_lines.append(f"Page: {display_page}")
        if is_excel:
            if sheet_name:
                meta_lines.append(f"Sheet: {sheet_name}")
            if row_start and row_end:
                meta_lines.append(f"Rows: {row_start}–{row_end}")
        if title:
            meta_lines.append(f"Title: {title}")
        if project:
            meta_lines.append(f"Project: {project}")

        meta_lines.append("Content: " + doc.page_content)
        context_blocks.append("\n".join(meta_lines))

    context_text = "\n\n---\n\n".join(context_blocks)

    response_format = {
        "type": "json_schema",
        "json_schema": {
            "name": "answer_with_sources",
            "schema": {
                "type": "object",
                "properties": {
                    "answer": {
                        "type": "string",
                        "description": (
                            "Answer the user's question clearly. "
                            "When helpful, reference relevant metadata (e.g., sheet names and row ranges "
                            "for Excel sources; page numbers for PDFs) that is present in the context."
                        )
                    },
                    "used_sources": {
                        "type": "array",
                        "items": {"type": "string"},
                        "description": "IDs of the sources actually used (e.g., ['source_1','source_3'])."
                    }
                },
                "required": ["answer", "used_sources"],
                "additionalProperties": False
            }
        }
    }

    system_prompt = (
        "You are a helpful assistant. Use ONLY the provided context to answer the user query.\n"
        "- IMPORTANT: If the user's question is vague or could apply to multiple items in the context, "
        "ALWAYS ask for clarification FIRST without providing any partial information or examples.\n"
        "- Only provide detailed answers when the user's question is specific enough to give a single, clear answer.\n"
        "- Common scenarios requiring clarification (ask for clarification WITHOUT giving examples):\n"
        "  * Questions like 'what is room area?' when multiple rooms exist - ask which specific room\n"
        "  * Questions about projects when multiple projects are present - ask which specific project\n"
        "  * Questions about 'what is the door height?' when multiple doors exist - ask which specific project\n"
        "  * Questions about slabs, sheets, or any items when multiple options exist - ask which specific one\n"
        "- When asking for clarification, be direct and helpful: 'Which specific room are you asking about?' "
        "or 'Could you specify which project you're referring to?'\n"
        "- If the context contains the exact information requested with no ambiguity, provide a complete answer.\n"
        "- If the requested details are not found in the context, say so politely: "
        "'I couldn't find that information in the provided material.'\n"
        "- Use precise metadata details (sheet names, row ranges, page numbers) naturally in your answers.\n"
        "- Do not mention terms like 'context provided' or 'document above'.\n"
        "Return JSON with keys:\n"
        '  - "answer": your answer text (ask for clarification when needed, or provide specific answer)\n'
        '  - "used_sources": array of Source IDs you actually relied on (empty if asking for clarification)\n'
    )

    messages = [{"role": "system", "content": system_prompt}, *chat_history, {
        "role": "user",
        "content": f"Query: {user_query}\n\nContext:\n{context_text}"
    }]

    response = client.chat.completions.create(
        model="gpt-4o",
        messages=messages,
        temperature=0.7,
        response_format=response_format
    )

    try:
        result = json.loads(response.choices[0].message.content)
        print("structured result", result)
        answer = result["answer"]
        used_source_ids = result["used_sources"]

        used_citations: list[str] = []
        for sid in used_source_ids:
            src = next((s for s in available_sources if s["id"] == sid), None)
            if not src:
                continue
            if src["is_excel"]:
                citation = f"[{src['display_label']}]({src['link']})"
            else:
                if src["page"]:
                    citation = f"[{src['display_label']}]({src['link']}) (Page {src['page']})"
                else:
                    citation = f"[{src['display_label']}]({src['link']})"
            if citation not in used_citations:
                used_citations.append(citation)

        if used_citations:
            citation_text = "\n".join(f"- {c}" for c in used_citations)
            final_answer = f"{answer}\n\n### Sources\n{citation_text}"
        else:
            final_answer = answer

        return final_answer

    except json.JSONDecodeError:
        return "Sorry we are unable to answer your query"
