---
paper: A4
margins: 25
header: "**{{organisation}}** — compte rendu de réunion"
header-align: right
footer: "Page {PAGE} sur {PAGES}"
footer-align: center
lang: fr
---

# Compte rendu : {{titre}}

**Date :** {{date_début}} · **Lieu :** {{lieu}} · **Rédigé par :** {{rédacteur}}

{{! Les commentaires comme celui-ci disparaissent du document produit. }}

## Participants

{{#participants}}

- **{{nom}}**, {{rôle}}

{{/participants}}

## Ordre du jour

{{ordre_du_jour}}

## Décisions

{{décisions}}

## Actions

| Action | Responsable | Échéance |
|---|---|---|
| {{#actions}}{{tâche}} | {{qui}} | {{quand}}{{/actions}} |

{{^actions}}

Aucune action n’a été décidée.

{{/actions}}

## Prochaine réunion

{{#prochaine_réunion}}

Le **{{date}}** à {{heure}}, {{lieu}}.

{{/prochaine_réunion}}

{{^prochaine_réunion}}

La date de la prochaine réunion n’est pas encore fixée.

{{/prochaine_réunion}}
