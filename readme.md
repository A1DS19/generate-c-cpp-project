### Installation:

Clone the repository first, then run the installer from inside it:

```bash
git clone <repo-url>
cd generate-c-cpp-project
```

#### C++ Installation

```bash
chmod +x generate-cpp-project.sh install-cpp.sh
./install-cpp.sh
```

#### C Installation

```bash
chmod +x generate-c-project.sh install-c.sh
./install-c.sh
```

The installer copies the scripts and the `lib/` directory to `/usr/local/share/generate-c-cpp-project/` and creates a wrapper command in `/usr/local/bin/`.

### Usage:

```bash
generate-cpp-project my-project-name
generate-c-project my-project-name
```

### Updating:

To update after pulling new changes, re-run the installer:

```bash
git pull
./install-cpp.sh   # re-installs C++ generator
./install-c.sh     # re-installs C generator
```
