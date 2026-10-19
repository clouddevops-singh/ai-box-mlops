import os
from typing import TypedDict

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field
from langchain_core.messages import HumanMessage
from langchain_openai import ChatOpenAI
from langgraph.graph import END, START, StateGraph


class ChatState(TypedDict):
    messages: list[HumanMessage]
    answer: str


def respond(state: ChatState) -> ChatState:
    """Use a configured OpenAI-compatible chat endpoint or a deterministic local echo."""
    question = state["messages"][-1].content
    if os.getenv("MODEL_BACKEND", "echo").lower() == "openai":
        model = ChatOpenAI(
            model=os.getenv("CHAT_MODEL", "gpt-4o-mini"),
            api_key=os.getenv("OPENAI_API_KEY"),
            base_url=os.getenv("OPENAI_BASE_URL") or None,
            timeout=30,
            max_retries=1,
        )
        response = model.invoke(state["messages"])
        return {**state, "answer": str(response.content)}
    return {**state, "answer": f"AI Box received: {question}"}


graph_builder = StateGraph(ChatState)
graph_builder.add_node("respond", respond)
graph_builder.add_edge(START, "respond")
graph_builder.add_edge("respond", END)
chat_graph = graph_builder.compile()

app = FastAPI(title="AI Box API", version="0.1.0")


class ChatRequest(BaseModel):
    message: str = Field(min_length=1, max_length=4000)


class ChatResponse(BaseModel):
    answer: str


@app.get("/healthz")
def healthz() -> dict[str, str]:
    return {"status": "ok"}


@app.get("/readyz")
def readyz() -> dict[str, str]:
    return {"status": "ready"}


@app.post("/chat", response_model=ChatResponse)
def chat(request: ChatRequest) -> ChatResponse:
    try:
        result = chat_graph.invoke({"messages": [HumanMessage(content=request.message)], "answer": ""})
        return ChatResponse(answer=result["answer"])
    except Exception as exc:  # Keep internal details out of the HTTP response.
        raise HTTPException(status_code=500, detail="Workflow execution failed") from exc
