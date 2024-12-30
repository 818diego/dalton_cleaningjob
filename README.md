# Dalton Cleaning Job

## Description

The **Dalton Cleaning Job** script is a resource for FiveM servers that allows players to perform vehicle cleaning jobs. Players can start the job, clean vehicles, and receive payments for their work. This is one of my first scripts, and I am still improving my practice. Any improvements for better performance are greatly appreciated.

## Features

- **Start and end job**: Players can start and end the cleaning job by interacting with an NPC.
- **Job progress**: Progress is shown through on-screen notifications.
- **Payments**: Players receive payments for each cleaned vehicle. If they do not finish the job, they receive a proportional payment.
- **Notifications**: On-screen notifications to inform players about the job status and received payments.
- **Multilanguage support**: Support for multiple languages (currently English and Spanish).
- **Fully configurable**: The script is highly configurable to suit your server's needs.
- **Bucket and sponge mechanics**: Players use a bucket and sponge to clean vehicles, adding realism to the job.
- **Context menu**: A context menu is available for job-related actions, such as taking or returning the bucket.
- **Vehicle interaction**: Players can only clean stopped vehicles, ensuring realistic job mechanics.

## Installation

1. **Download** the script and place it in your server's `resources` folder.
2. **Add** the resource to your `server.cfg` file:
    ```plaintext
    ensure dalton_cleaningjob
    ```
3. If you already have a folder initialized with your scripts, simply move the script to that folder.

> [!IMPORTANT]
> Make sure to restart your server after adding the script for the changes to take effect.

## Usage

### Interaction

- **Start job**: Players can start the cleaning job by interacting with an NPC using `ox_target`.
- **End job**: Players can end the cleaning job by interacting with the NPC again.
- **Take bucket**: Players can take a bucket to start cleaning vehicles.
- **Place bucket**: Players can place the bucket on the ground to use it.
- **Wet sponge**: Players can wet the sponge using the bucket to clean vehicles.
- **Return bucket**: Players can return the bucket to end the job.

> [!TIP]
> Use `ox_target` for smoother interaction with NPCs.

### Configuration

The script's language can be configured in the `config.lua` file:
```lua
Config = {}
Config.Language = 'en' -- Change to 'es' for Spanish
```

> [!NOTE]
> You can add more languages by creating new JSON files in the `locales` folder.

## Localization

The script supports multiple languages. Localization files are located in the `locales` folder:
- `locales/en.json` for English
- `locales/es.json` for Spanish

## Dependencies

This script depends on the following resources:
- `qbx_core`
- `ox_target`
- `ox_lib`

Make sure to have these resources installed and configured on your server.

## Contributions

Contributions are welcome. If you want to add new features or fix bugs, please open a pull request in the project repository.

> [!NOTE]
> This script is only for Qbox. If anyone wants to adapt it for QBCore, please submit a Pull Request (PR).

> [!TIP]
> This is my first script, and any recommendations or help to do certain things are welcome and greatly appreciated.

## License

This project is licensed under the MIT License. See the `LICENSE` file for more details.
