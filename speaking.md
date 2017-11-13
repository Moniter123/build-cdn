---
title: Public speaking
layout: page
description: Janos Pasztors public speaking engagements
---
<div class="container-block">
    <h1 class="text-center">Public Speaking Engagements</h1>
</div>
{% for post in site.categories.speaking %}
<div class="container-block">
    <h2>{{ post.title }}{% if post.eventName %} &mdash; {{ post.eventName }}{% endif %}{% if post.inLanguage and post.inLanguage != "EN" %} ({{ post.inLanguage }}){% endif %}</h2>
    <p class="mt mb excerpt">{{post.excerpt}}</p>
    <div class="mt mb">
        {% if post.slides %}
            <a href="{{post.slides}}" class="btn learnmore" target="blank" rel="noopener noreferrer" download>Download slides <img src="{% base64 /assets/download.svg %}" alt="" class="icon" /></a>
        {% endif %}
        {% if post.video %}
            <a href="{{post.video}}" class="btn learnmore" target="blank" rel="noopener noreferrer">Watch video (external site) <img src="{% base64 /assets/diagonal-arrow.svg %}" alt="" class="icon" /></a>
        {% endif %}
        {% if post.external_link %}
            <a href="{{post.external_link}}" class="btn learnmore" target="blank" rel="noopener noreferrer">Event page (external site) <img src="{% base64 /assets/diagonal-arrow.svg %}" alt="" class="icon" /></a>
        {% endif %}
    </div>
    {% assign date_format = "%b %-d, %Y" %}
    <script type="application/ld+json">
    {
      "@context": "http://schema.org",
      "@type": "Event",
      "name": "{{ post.title }}",
      "startDate": "{{ post.talkStartDate }}",
      "endDate": "{{ post.talkEndDate }}",
      "url": "{{ post.url | absolute_url }}",
      "inLanguage": "{{ post.inLanguage}}",
      "superEvent": {
        "@context": "http://schema.org",
        "@type": "Event",
        "name": "{{ post.eventName }}",
        "url": "{{ post.eventUrl }}",
        "startDate": "{{ post.eventStartDate }}",
        "endDate": "{{ post.eventEndDate }}",
        "location": {
          "@type": "Place",
          "name": "{{ post.eventLocationName }}",
          "address": {
            "@type": "PostalAddress",
            "streetAddress": "{{ post.eventStreetAddress }}",
            "addressLocality": "{{ post.eventCity }}",
            "postalCode": "{{ post.eventPostalCode }}",
            "addressCountry": "{{ post.eventCountry }}"
          }
        }
      },
      "location": {
        "@type": "Place",
        "name": "{{ post.eventLocationName }}",
        "address": {
          "@type": "PostalAddress",
          "streetAddress": "{{ post.eventStreetAddress }}",
          "addressLocality": "{{ post.eventCity }}",
          "postalCode": "{{ post.eventPostalCode }}",
          "addressCountry": "{{ post.eventCountry }}"
        }
      },
      "performer": {
        "@type": "Person",
        "name": "Janos Pasztor",
        "url": "https://pasztor.at/"
      }
    }
    </script>
</div>
{% if forloop.last == false %}
<hr />
{%endif%}
{% endfor %}
