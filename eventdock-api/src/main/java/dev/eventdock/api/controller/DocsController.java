package dev.eventdock.api.controller;

import io.swagger.v3.oas.annotations.Hidden;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Serves the interactive Swagger UI directly on root (/) and (/docs)
 * allowing users to view API documentation at https://api.eventdock.swynx.dev/#docs or /docs.
 */
@RestController
@Hidden
public class DocsController {

    private static final String SWAGGER_DOCS_HTML = """
            <!DOCTYPE html>
            <html lang="en">
              <head>
                <meta charset="UTF-8">
                <title>EventDock Platform API - Documentation</title>
                <link rel="stylesheet" type="text/css" href="/swagger-ui/swagger-ui.css" />
                <link rel="stylesheet" type="text/css" href="/swagger-ui/index.css" />
                <link rel="icon" type="image/png" href="/swagger-ui/favicon-32x32.png" sizes="32x32" />
                <link rel="icon" type="image/png" href="/swagger-ui/favicon-16x16.png" sizes="16x16" />
                <style>
                  html { box-sizing: border-box; overflow: -moz-scrollbars-vertical; overflow-y: scroll; }
                  *, *:before, *:after { box-sizing: inherit; }
                  body { margin: 0; background: #fafafa; }
                  .topbar { display: none !important; }
                </style>
              </head>
              <body>
                <div id="swagger-ui"></div>
                <script src="/swagger-ui/swagger-ui-bundle.js" charset="UTF-8"></script>
                <script src="/swagger-ui/swagger-ui-standalone-preset.js" charset="UTF-8"></script>
                <script src="/swagger-ui/swagger-initializer.js" charset="UTF-8"></script>
              </body>
            </html>
            """;

    @GetMapping(value = {"/", "/docs"}, produces = MediaType.TEXT_HTML_VALUE)
    public ResponseEntity<String> serveDocs() {
        return ResponseEntity.ok()
                .contentType(MediaType.TEXT_HTML)
                .body(SWAGGER_DOCS_HTML);
    }
}
