---
title: Blog
layout: page
description: Read the IT blog of Janos Pasztor
---
<div class="container-block">
    <h1 class="text-center">Latest Blog Posts</h1>
</div>
{% for post in site.categories.blog %}
<div class="container-block">
    <h2>{{ post.title }}</h2>
    <p class="mt mb excerpt">{{post.excerpt}}</p>
    <div class="mt mb">
        {% if post.external_link %}
            <a href="{{post.external_link}}" class="btn learnmore">Learn more (external site) <img src="{% base64 /assets/diagonal-arrow.svg %}" alt="" class="icon" /></a>
        {% else %}
            <a href="{{post.url}}" class="btn learnmore">Read more <img src="{% base64 /assets/right-arrow.svg %}" alt="" class="icon" /></a>
        {% endif %}
    </div>
    {% assign date_format = "%b %-d, %Y" %}
    <script type="application/ld+json">
    {
      "@context":"http://schema.org",
      "@type":"BlogPosting",
      "title": "{{ post.title | escape }}",
      "datePublished": "{{ post.date | date: date_format }}",
      "url": "{{post.url|absolute_url}}",
      "author": {
        "@type": "Person",
        "name": "Janos Pasztor",
        "url": "https://pasztor.at/"
      }
    }
    </script>
</div>
{% if forloop.last == false %}
<hr />
{% endif %}
{% endfor %}
