---
title: Blog
layout: default
description: Read the IT blog of Janos Pasztor
---

<div class="wall">
<div class="wall__postlist">
{% for post in site.categories.blog %}
{% include wall-post.html %}
{% endfor %}
</div>
</div>
