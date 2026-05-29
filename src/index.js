export default {
    async fetch() {
        const r = await fetch(
             "https://raw.githubusercontent.com/leonx24/Leon-x/main/ui/library.lua"
        )

        return new Response(await r.text(), {
            headers: {
                "content-type": "text/plain"
            }
        })
    }
}