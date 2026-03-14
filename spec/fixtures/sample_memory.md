# Test Project Memory

## Hard Rules
- Never delete production data without confirmation
- Always use snake_case for Ruby methods

## Key Architecture Facts
- Ruby gem ecosystem with auto-discovered extensions
- RabbitMQ for task distribution via `legion-transport`
- MySQL via `Sequel` ORM for persistence

## CLI Gotchas
- Thor reserves `run` as a method name
- `::Process` must be explicit inside `Legion::` namespace
- `::JSON` must be explicit inside `Legion::` namespace

## Identity Auth Pattern
- Digital Worker = Entra ID **Application** (service principal)
- Dual-layer: OIDC client credentials + behavioral entropy

## Project Structure
- Workspace: `/tmp/test`
- 10 repos total
