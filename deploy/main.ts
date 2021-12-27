/// <reference path="./types.d.ts" />

/** Auth token used to access GitHub release artifacts. */
const token = Deno.env.get("TOKEN");

/** Handle network requests. */
async function respond(request: Request): Promise<Response> {
  if (!token) return new Response("Invalid token");

  const { pathname } = new URL(request.url);

  /** The requested file name. */
  const file = pathname.substring(1);

  /** A reusable header with authorization. */
  const headers = new Headers({ Authorization: token });

  /** Latest release artifacts from GitHub. */
  const data = await fetch(
    "https://api.github.com/repos/lemueld6200/my_afse/releases/latest",
    { headers }
  );

  const { tag_name: tag, assets } = await data.json();

  /** The latest version. */
  const version = tag.substring(1);

  // If no file is requested, return the latest version.
  if (!file) return new Response(version);

  headers.set("accept", "application/octet-stream");

  // Iterate through every release artifacts, and match for the requested file.
  for (const { name, url } of assets)
    if (file === name) {
      /**
       * As GitHub became more strict about fetching artifacts,
       * we're manually getting the redirect URL, then returning
       * another fetch request containing the file data.
       */
      const redirect = await fetch(url, { headers, redirect: "manual" });

      return fetch(redirect.headers.get("location")!);
    }

  return new Response("File not found");
}

// Listen for network requests.
addEventListener("fetch", (event) => event.respondWith(respond(event.request)));
