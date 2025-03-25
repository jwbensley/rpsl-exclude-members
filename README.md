# draft-bensley-rpsl-exclude-members

This repo contains the working draft text. The [Markdown](draft/draft-bensley-rpsl-exclude-members.md) file is the authoritative source.

## Editing

Starting the docker container will render the Markdown text to RFC XML and HTML. A HTTP server will then start which serves the rendered HTML.

Whenever changes to the Markdown file are saved, new XML and HTML versions are rendered. Simply refresh your browser to see the changes.

```shell
docker compose up
...
render-1  | Open your browser to: http://127.0.0.1:4343/draft-bensley-rpsl-exclude-members.html
```
