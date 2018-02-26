---
title: Projects
layout: default
description: Open source projects by Janos Pasztor
---

<div class="wall">
<div class="wall__postlist">
{% for post in site.categories.projects %}
{% include wall-post.html %}
{% endfor %}
</div>
</div>
