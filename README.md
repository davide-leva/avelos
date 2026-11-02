# Avelos

Avelos è la mia immagine desktop Linux personale, mantenuta da [davide-leva](https://github.com/davide-leva). Nasce come fork di Morros ed è basata su Bazzite e sul template di Universal Blue per immagini bootc.

## Desktop e software

La configurazione attuale usa `ghcr.io/ublue-os/bazzite-gnome:stable` come base e aggiunge:

- MangoWM come compositor Wayland, Noctalia v5 e il login manager greetd con noctalia-greeter.
- Stack grafico Mesa per GPU integrate Intel e AMD, senza la variante NVIDIA della base né NVIDIA Container Toolkit.
- Homebrew, strumenti di sviluppo e container, QEMU/KVM e virt-manager.
- Applicazioni desktop come Kitty, Nautilus, mpv e OBS Studio.
- OpenSnitch come firewall applicativo.

MangoWM e noctalia-greeter vengono installati dal repository Terra; Noctalia dal repository Fedora. greetd avvia `/usr/bin/noctalia-greeter-session`: nella schermata di accesso selezionare **Mango**. Noctalia parte automaticamente con la sessione.

La configurazione Mango viene installata sia in `/etc/mango/config.conf` (fallback di sistema) sia in `/etc/skel/.config/mango/config.conf` (nuovi utenti). Gli utenti esistenti possono copiarla in `~/.config/mango/config.conf`; eventuali configurazioni personali già presenti hanno precedenza. Non sono fissati nomi di monitor o dispositivi GPU, così la stessa immagine può essere usata sulle due macchine. Il layout tastiera iniziale è `us` e si modifica con `xkb_rules_layout`.

Scorciatoie iniziali: `Super+Invio` apre Kitty, `Super+Spazio` il launcher Noctalia, `Super+E` Nautilus, `Super+Q` chiude la finestra e `Super+1…9` cambia workspace. `Super+Shift+R` ricarica la configurazione, `Super+Shift+M` termina la sessione.

I portali GTK e wlroots gestiscono selezione file e condivisione schermo; Slurp permette di selezionare lo schermo da condividere. Lo stato persistente del greeter viene inizializzato all'avvio, prima di greetd, da `avelos-greeter-setup.service`.

Le configurazioni Kitty presenti nel repository non vengono ancora installate dalla build.

## Build locale

Servono Podman e `just`. Per costruire l'immagine `avelos:latest`:

```bash
just build
```

Per creare un'immagine disco o una ISO dalla build locale:

```bash
just build-qcow2
just build-iso
```

Le impostazioni dei dischi sono in [`disk_config/disk.toml`](disk_config/disk.toml); quelle dell'installer sono in [`disk_config/iso.toml`](disk_config/iso.toml). L'installer è configurato per usare `ghcr.io/davide-leva/avelos:latest` dopo l'installazione.

Per vedere tutti i comandi disponibili:

```bash
just --list
```

## Build e pubblicazione su GitHub

Il workflow [build.yml](.github/workflows/build.yml) costruisce l'immagine e, sul branch predefinito, la pubblica su GHCR. Nome e proprietario sono ricavati dal repository: per `davide-leva/avelos` la destinazione è `ghcr.io/davide-leva/avelos:latest`.

La build parte sui push a `main` (escluse le modifiche al solo README), sulle pull request verso `main`, ogni giorno e su avvio manuale. Il workflow [build-disk.yml](.github/workflows/build-disk.yml) gestisce le immagini disco e gli artefatti dell'installer.

### Firma dell'immagine

Il workflow usa il secret `SIGNING_SECRET` per firmare l'immagine con Cosign. Il file `cosign.pub` proviene dal fork: prima di pubblicare immagini firmate a proprio nome, occorre sostituirlo con la propria chiave pubblica e configurare il secret corrispondente.

Per creare una nuova coppia di chiavi con Cosign installato:

```bash
COSIGN_PASSWORD="" cosign generate-key-pair
```

Il file privato `cosign.key` è escluso da Git e va conservato privatamente. Il suo contenuto va inserito nel secret GitHub Actions `SIGNING_SECRET`; la chiave pubblica `cosign.pub` va aggiunta al repository.

## Passare ad Avelos

Dopo aver pubblicato l'immagine, su un sistema compatibile con bootc:

```bash
sudo bootc switch ghcr.io/davide-leva/avelos:latest
```

Riavviare per applicare il cambio. La configurazione è pensata per macchine x86_64 con grafica integrata Intel o AMD.

## Riferimenti del desktop

- [Installazione MangoWM](https://mangowm.github.io/docs/installation/)
- [Installazione Noctalia](https://docs.noctalia.dev/noctalia/getting-started/installation/)
- [Integrazione Noctalia con Mango](https://docs.noctalia.dev/noctalia/compositor-settings/mango/)
- [Configurazione noctalia-greeter](https://docs.noctalia.dev/greeter/installation/)

## Personalizzazione

- [`Containerfile`](Containerfile): immagine di base e fasi della build.
- [`build_files/build.sh`](build_files/build.sh): pacchetti, servizi e configurazioni installati.
- [`build_files/dot_config`](build_files/dot_config): configurazioni desktop.
- [`Justfile`](Justfile): comandi per build e macchine virtuali; il nome predefinito è `avelos`.
- [`artifacthub-repo.yml`](artifacthub-repo.yml): configurazione opzionale, ancora da compilare per registrare il progetto su Artifact Hub.

## Origini e licenza

Avelos deriva da Morros e dal progetto [Universal Blue image-template](https://github.com/ublue-os/image-template), e utilizza [Bazzite](https://github.com/ublue-os/bazzite) come base. La licenza del repository è [Apache-2.0](LICENSE).
