# Website

Current version is powered by Eleventy

## Development

Run `yarn dev` to start a local development environment with hot reload 

Add a `name_of_post.md` file to `src/posts` 

### Shortcodes
1. `img` shortcode allows insertion of `<img>` tag with arbitrary attributes\
    Example:
    ```markdown
    {% img "/images/predicate-generator/MathFirstScreenshot.png" 'align="left"' 'style="width: 40%;"'%}
    ```
    All arguments after the content link will be treated as strings to be inserted inside the `<img>` tag\
    This produces
    ```html
    <img src="/images/predicate-generator/MathFirstScreenshot.png" alt="MathFirstScreenshot.png" align="left" style="width: 40%;">
    ```