/*! coi-serviceworker v0.1.7 - Guido Zufolo (MIT) */
if (typeof window !== "undefined") {
    const n = navigator;
    if (n.serviceWorker) {
        n.serviceWorker.register("coi-serviceworker.js").then(
            (registration) => {
                if (registration.active && !n.serviceWorker.controller) {
                    window.location.reload();
                }
                registration.addEventListener("updatefound", () => {
                    window.location.reload();
                });
            },
            (err) => {
                console.error("COOP/COEP Service Worker failed to register:", err);
            }
        );
        n.serviceWorker.addEventListener("controllerchange", () => {
            window.location.reload();
        });
    }
} else {
    self.addEventListener("install", () => self.skipWaiting());
    self.addEventListener("activate", (event) => event.waitUntil(self.clients.claim()));

    self.addEventListener("fetch", (event) => {
        const request = event.request;
        if (request.cache === "only-if-cached" && request.mode !== "same-origin") {
            return;
        }

        event.respondWith(
            fetch(request)
                .then((response) => {
                    if (response.status === 0) {
                        return response;
                    }

                    const newHeaders = new Headers(response.headers);
                    newHeaders.set("Cross-Origin-Opener-Policy", "same-origin");
                    newHeaders.set("Cross-Origin-Embedder-Policy", "credentialless");

                    return new Response(response.body, {
                        status: response.status,
                        statusText: response.statusText,
                        headers: newHeaders,
                    });
                })
                .catch((e) => console.error(e))
        );
    });
}