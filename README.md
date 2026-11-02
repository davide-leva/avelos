# Avelos

Avelos è la mia immagine desktop Linux personale, mantenuta da [davide-leva](https://github.com/davide-leva). Nasce come fork di Morros ed è basata su Bazzite e sul template di Universal Blue per immagini bootc.

## Desktop e software

La configurazione attuale usa `ghcr.io/ublue-os/bazzite-gnome-nvidia:stable` come base e aggiunge:

- Niri come compositor Wayland, Dank Material Shell e il login manager greetd con dms-greeter.
- Driver e strumenti della base NVIDIA, con NVIDIA Container Toolkit aggiunto dalla build.
- Homebrew, strumenti di sviluppo e container, QEMU/KVM e virt-manager.
- Applicazioni desktop come Kitty, Nautilus, mpv e OBS Studio.
- OpenSnitch come firewall applicativo.

Le impostazioni Niri vengono copiate in `/etc/skel/.config/niri`: sono i valori iniziali per i nuovi utenti. Le configurazioni Kitty presenti nel repository non vengono ancora installate dalla build.

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

Riavviare per applicare il cambio. La configurazione attuale è pensata per hardware NVIDIA.

## Personalizzazione

- [`Containerfile`](Containerfile): immagine di base e fasi della build.
- [`build_files/build.sh`](build_files/build.sh): pacchetti, servizi e configurazioni installati.
- [`build_files/dot_config`](build_files/dot_config): configurazioni desktop.
- [`Justfile`](Justfile): comandi per build e macchine virtuali; il nome predefinito è `avelos`.
- [`artifacthub-repo.yml`](artifacthub-repo.yml): configurazione opzionale, ancora da compilare per registrare il progetto su Artifact Hub.

## Origini e licenza

Avelos deriva da Morros e dal progetto [Universal Blue image-template](https://github.com/ublue-os/image-template), e utilizza [Bazzite](https://github.com/ublue-os/bazzite) come base. La licenza del repository è [Apache-2.0](LICENSE).
