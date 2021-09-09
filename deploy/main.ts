/// <reference path="./types.d.ts" />

const token = Deno.env.get("TOKEN");

if (token)
  addEventListener("fetch", async (event) => {
    const data = await fetch(
      "https://api.github.com/repos/lemueld6200/my_afse/releases/latest",
      { headers: { Authorization: token } }
    );

    const { tag_name, assets } = await data.json();

    event.respondWith(
      new Response(
        JSON.stringify({
          version: tag_name.substring(1),
          url: assets[0].browser_download_url,
        }),
        { headers: { accept: "application/json" } }
      )
    );
  });
