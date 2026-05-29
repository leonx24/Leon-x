export default {
    async fetch() {
        return new Response(`
print("Leon X Loaded")
`, {
            headers: {
                "content-type": "text/plain"
            }
        })
    }
}