---
layout: home
description: Latest posts by Janos Pasztor
---

<div class="wall">
<div class="wall__featurelist">
    {% for post in site.posts limit:2 %}
        {% include wall-post.html %}
    {% endfor %}
</div>
<div class="wall__postlist">
    {% for post in site.posts offset:2 limit:8 %}
        {% include wall-post-noimage.html %}
    {% endfor %}
</div>
</div>

<div class="readmore">
    <div class="readmore__cta">Do you want more? Click the buttons below!</div>
    <div class="readmore__buttons">
        <a href="/speaking" class="readmore__button">Talks</a>
        <a href="/workshops" class="readmore__button">Workshops</a>
        <a href="/blog" class="readmore__button">Blog</a>
    </div>
</div>