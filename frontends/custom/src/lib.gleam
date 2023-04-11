import gleam/uri.{Uri}

pub external fn glue_document_url() -> String =
  "./glue.js" "document_url"

pub fn document_uri() -> Result(Uri, Nil) {
  uri.parse(glue_document_url())
}
