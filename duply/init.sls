#!jinja|yaml

{% from 'duply/defaults.yaml' import rawmap_osfam with context %}
{% set datamap = salt['grains.filter_by'](rawmap_osfam, merge=salt['pillar.get']('duply:lookup')) %}

include: {{ datamap.sls_include|default([]) }}
extend: {{ datamap.sls_extend|default({}) }}

duply:
  pkg:
    - installed
    - pkgs: {{ datamap.pkgs }}

{% for k, v in datamap.profiles|default({})|dictsort if k != 'common' %}
  {% set prof_loc = v.profile_location|default('/root/.duply') %}
  {% set common_prof = datamap.profiles.common|default({}) %}

duply_profile_{{ k }}_parent_dir:
  file:
    - directory
    - name: {{ prof_loc }}
    - mode: 700
    - user: root

duply_profile_{{ k }}_dir:
  file:
    - {{ v.ensure|default('directory') }}
    - name: {{ prof_loc }}
    - name: {{ prof_loc }}/{{ k }}
    - mode: 700
    - user: root

{% if v.ensure|default('directory') != 'absent' %}

duply_profile_{{ k }}_conf:
  file:
    - managed
    - name: {{ prof_loc }}/{{ k }}/conf
    - source: {{ v.profile_template_path|default('salt://duply/files/profile_conf') }}
    - mode: 600
    - user: root
    - template: jinja
    - context:
      common_settings: {{ common_prof.conf|default({}) }}
      settings: {{ v.conf }}
      dupl_params: {{ v.dupl_params|default([]) }}

duply_profile_{{ k }}_exclude:
  file:
    - managed
    - name: {{ prof_loc }}/{{ k }}/exclude
    - source: {{ v.exclude_template_path|default('salt://duply/files/exclude') }}
    - mode: 600
    - user: root
    - template: jinja
    - context:
      excludes: {{ v.excludes|default({}) }}

    {% if 'pre' in v %}
duply_profile_{{ k }}_pre_script:
  file:
    - managed
    - name: {{ prof_loc }}/{{ k }}/pre
      {% if 'contents' in v.pre %}
    - contents_pillar: duply:lookup:profiles:{{ k }}:pre:contents
      {% else %}
    - source: {{ v.pre.template_path|default('salt://duply/files/pre') }}
      {% endif %}
    - mode: 700
    - user: root
    - template: jinja
    {% endif %}

    {% if 'post' in v %}
duply_profile_{{ k }}_post_script:
  file:
    - managed
    - name: {{ prof_loc }}/{{ k }}/post
      {% if 'contents' in v.post %}
    - contents_pillar: duply:lookup:profiles:{{ k }}:post:contents
      {% else %}
    - source: {{ v.post.template_path|default('salt://duply/files/post') }}
      {% endif %}
    - mode: 700
    - user: root
    - template: jinja
    {% endif %}
  {% endif %}
{% endfor %}
