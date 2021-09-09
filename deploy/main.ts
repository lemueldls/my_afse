/// <reference path="./types.d.ts" />

const token = Deno.env.get("TOKEN");

console.log(token);

if (token)
  addEventListener("fetch", async (event) => {
    event.respondWith(
      await fetch(
        "https://api.github.com/repos/lemueld6200/my_afse/releases/latest",
        {
          headers: { Authorization: token },
        }
      )
    );
  });
