# Dalton Cleaning Job

## Descripción

El script **Dalton Cleaning Job** es un recurso para servidores de FiveM que permite a los jugadores realizar trabajos de limpieza de vehículos. Los jugadores pueden iniciar el trabajo, limpiar vehículos y recibir pagos por su trabajo.

## Características

- **Inicio y finalización del trabajo**: Los jugadores pueden iniciar y finalizar el trabajo de limpieza interactuando con un NPC.
- **Progreso del trabajo**: El progreso se muestra mediante notificaciones en pantalla.
- **Pagos**: Los jugadores reciben pagos por cada vehículo limpiado. Si no terminan el trabajo, reciben un pago proporcional.
- **Notificaciones**: Notificaciones en pantalla para informar a los jugadores sobre el estado del trabajo y los pagos recibidos.
- **Soporte multilenguaje**: Soporte para múltiples idiomas (actualmente inglés y español).
- **Totalmente configurable**: El script es altamente configurable para adaptarse a las necesidades de tu servidor.

## Instalación

1. **Descarga** el script y colócalo en la carpeta `resources` de tu servidor FiveM.
2. **Añade** el recurso a tu archivo `server.cfg`:
    ```plaintext
    ensure dalton_cleaningjob
    ```
3. Si ya tienes una carpeta inicializada con tus scripts, simplemente mueve el script a esa carpeta.

> [!IMPORTANT]
> Asegúrate de reiniciar tu servidor después de añadir el script para que los cambios surtan efecto.

## Uso

### Interacción

- **Iniciar trabajo**: Los jugadores pueden iniciar el trabajo de limpieza interactuando con un NPC utilizando `ox_target`.
- **Finalizar trabajo**: Los jugadores pueden finalizar el trabajo de limpieza interactuando nuevamente con el NPC.

> [!TIP]
> Utiliza `ox_target` para una interacción más fluida con los NPCs.

### Configuración

El idioma del script se puede configurar en el archivo de configuración `config.lua`:
```lua
Config = {}
Config.Language = 'en' -- Cambiar a 'es' para español
```

> [!NOTE]
> Puedes agregar más idiomas creando nuevos archivos JSON en la carpeta `locales`.

## Localización

El script soporta múltiples idiomas. Los archivos de localización se encuentran en la carpeta `locales`:
- `locales/en.json` para inglés
- `locales/es.json` para español

## Dependencias

Este script depende de los siguientes recursos:
- `qbx_core`
- `ox_target`
- `ox_lib`

Asegúrate de tener estos recursos instalados y configurados en tu servidor.

## Contribuciones

Las contribuciones son bienvenidas. Si deseas agregar nuevas características o corregir errores, por favor abre un pull request en el repositorio del proyecto.

> [!NOTE]
> Este script es solo para Qbox. Si alguien desea adaptarlo para QBCore, por favor envíe un Pull Request (PR).

> [!TIP]
> Este es mi primer script, y cualquier recomendación o ayuda para realizar ciertas cosas son bienvenidas y muy agradecidas.

## Licencia

Este proyecto está licenciado bajo la Licencia MIT. Consulta el archivo `LICENSE` para más detalles.
