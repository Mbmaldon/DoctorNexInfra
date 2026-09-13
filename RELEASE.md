# Promoción de QA a producción

Cómo se lleva un cambio de `qa` a `main` en los tres repos de DoctorNex.

Este documento vive aquí, y no dentro de cada repo, porque el proceso los cruza
a los tres y tres copias se desincronizan a la primera.

| Repo | Rama de trabajo | Rama de producción |
|---|---|---|
| `DoctorNexBackendCore` | `qa` | `main` |
| `DoctorNexBackendAuth` | `qa` | `main` |
| `DoctorNexFrontend` | `qa` | `main` |

## El orden importa

**Core → Auth → Frontend.** Siempre.

El frontend lee campos que los backends tienen que estar sirviendo ya. Si se
promueve primero, la app pide datos que todavía no existen y la pantalla se
rompe para el usuario que esté dentro en ese momento.

Entre Core y Auth el orden pesa menos, pero Core primero es la costumbre: es el
que suele relajar restricciones (columnas que se vuelven opcionales) que Auth
después aprovecha.

## Antes de promover

**Respaldo de la base de datos de producción.** Es lo único del proceso que no
se puede deshacer. Todo lo demás se revierte con un commit.

**Revisar qué borra cada migración.** Buscar en las migraciones nuevas:

```bash
git diff --name-only --diff-filter=A origin/main origin/qa -- prisma/migrations/ \
  | grep migration.sql \
  | while read f; do
      git show origin/qa:"$f" | grep -inE "^\s*(DELETE|TRUNCATE|DROP)|SET\s+.*=\s*NULL" \
        && echo "  ↑ en $f"
    done
```

Lo que salga va escrito en el cuerpo del PR, explicando qué se pierde y qué se
conserva. Un `SET ... = NULL` cuenta como pérdida aunque no sea un `DROP`.

**CI en verde** en la rama `qa` de los tres repos.

## Las migraciones corren solas

No hay paso manual. `scripts/deploy-lightsail.sh` ejecuta
`npm run prisma:deploy` (que es `prisma migrate deploy`) **sobre la imagen
nueva y antes de reemplazar el contenedor vivo**. Si la migración falla:

- revierte el tag al anterior,
- **no toca el servicio en ejecución**,
- y el deploy termina en error.

O sea: nunca hay una ventana con código nuevo contra esquema viejo. Es el
mismo mecanismo en Core y en Auth.

Prisma lleva registro en `_prisma_migrations`, así que una migración ya
aplicada nunca se reaplica. Redesplegar es seguro.

## Promover

Un PR por repo, `head = qa`, `base = main`, en el orden de arriba. Se espera a
que termine el deploy de uno antes de mergear el siguiente.

## Después del merge: verificar que `qa` sobrevivió

```bash
git fetch -p origin && git branch -r | grep qa
```

GitHub borra la rama origen de un PR al mergearlo cuando el repo tiene
`delete_branch_on_merge` prendido. Como aquí la rama origen **es `qa`**, se la
llevaba en cada release.

La opción está **apagada** en los tres repos desde el 13 de septiembre de 2026:

```bash
gh api repos/Mbmaldon/<repo> --jq '.delete_branch_on_merge'   # debe decir false
```

A cambio, las ramas de feature ya no se borran solas. Se limpian a mano cada
tanto:

```bash
git fetch -p origin
git branch --merged origin/main | grep -vE '^\*|main|qa'      # revisar antes
git branch -d <rama>
```

Proteger `qa` contra borrado sería mejor que apagar la opción, pero
`branch protection` requiere GitHub Pro y estos repos son privados en plan
gratuito.

### Si `qa` ya se borró

No se pierde nada: el merge copió todo a `main` antes de borrar la rama.
Primero confirmar que la `qa` local no tiene commits propios:

```bash
git rev-list --count origin/main..qa     # tiene que dar 0
```

Si da `0`, se recrea desde producción:

```bash
git checkout qa
git fetch origin
git reset --hard origin/main
git push -u origin qa
```

Si da algo distinto de `0`, **no resetear**: hay trabajo local que solo existe
ahí. Revisarlo commit por commit antes de tocar nada.

Ese push dispara el pipeline de QA y deja el ambiente de QA sirviendo lo mismo
que producción, que es la posición correcta para empezar el siguiente ciclo.

## Publicar la nota de versión

Va **después** de que terminen los deploys. Si se publica antes, los doctores
reciben la notificación y entran a buscar cambios que todavía no existen.

El endpoint acepta la nota completa con todos sus ítems en un solo POST; la
pantalla de administración es la que obliga a capturarlos uno por uno.

Dos requests, y **son dos dominios distintos** — es el error fácil:

```
POST https://auth.doctornex.mx/auth/login      → devuelve { token }
POST https://api.doctornex.mx/admin/release-notes
     Authorization: Bearer <token>
```

En QA: `auth-qa.doctornex.mx` y `api-qa.doctornex.mx`.

Cuerpo:

```json
{
  "version": "1.13.0",
  "title": "Título de la actualización",
  "releasedAt": "2026-09-13T12:00:00.000Z",
  "items": [
    { "category": "feature", "description": "Sección - qué cambió" }
  ]
}
```

| Campo | Regla |
|---|---|
| `version` | ≤ 20 caracteres |
| `title` | ≤ 150 caracteres |
| `releasedAt` | ISO 8601 |
| `items[].category` | `feature` · `improvement` · `fix` · `style` |
| `items[].description` | 1 a 300 caracteres |

`feature` se muestra como **Nuevo**, `improvement` como **Mejora**, `fix` como
**Corrección**, `style` como **Estilo**. La convención del texto es
`Sección - qué cambió`, escrito para el doctor, no para quien programó.

Crear la nota **notifica automáticamente** a todos los doctor-admin. No hay que
hacer nada más.

El POST requiere rol `admin`; un `doctor-admin` solo puede leer el historial.

No existe endpoint para agregar ítems a una nota ya creada: el `PATCH`
reemplaza el arreglo completo. Para corregir se reenvían todos los ítems.

## Checklist

- [ ] Respaldo de la base de producción
- [ ] Revisadas las migraciones destructivas y documentadas en el PR
- [ ] CI verde en `qa` en los tres repos
- [ ] PR Core → merge → deploy verde
- [ ] PR Auth → merge → deploy verde
- [ ] PR Frontend → merge → deploy verde
- [ ] `origin/qa` sigue existiendo en los tres repos
- [ ] Nota de versión publicada
- [ ] Verificado con un usuario real que lo que se prometió se ve
