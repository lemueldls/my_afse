/// <reference path="./types.d.ts" />

const token = Deno.env.get("TOKEN");

async function respond(request: Request): Promise<Response> {
  if (!token) return new Response("Invalid token");

  const { pathname } = new URL(request.url);

  const file = pathname.substring(1);

  const headers = new Headers({ Authorization: token });

  const data = await fetch(
    "https://api.github.com/repos/lemueld6200/my_afse/releases/latest",
    { headers }
  );

  const { tag_name, assets } = await data.json();

  const version = tag_name.substring(1);

  if (!file) return new Response(version);

  headers.set("accept", "application/octet-stream");

  for (const { name, url } of assets) {
    if (file === name) return fetch(url, { headers });
  }

  return new Response("File not found");
}

addEventListener("fetch", (event) => event.respondWith(respond(event.request)));
