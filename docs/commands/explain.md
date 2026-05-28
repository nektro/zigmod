## `explain` command

```
zigmod explain
```

Use this command to create a visual description of your dependency graph.

## `--locked`

Pass this to use the dependency versions from `zigmod.lock` instead of your current `.zigmod` folder.

## `--format`

May be followed by one of the following values:

- `tree`
- `mermaid`
- `dot`

## `--format tree`

<img width="1077" height="866" alt="Image" src="https://github.com/user-attachments/assets/98d41e63-f5bd-4c7d-a5a3-272b9499d925" />

## `--format mermaid`

https://docs.github.com/en/get-started/writing-on-github/working-with-advanced-formatting/creating-diagrams

<img width="1173" height="373" alt="Image" src="https://github.com/user-attachments/assets/0ad012b2-cfc9-4a7a-b3fa-9f5fefb969ab" />

## `--format dot`

This format prints output compatible with the `dot` program from https://graphviz.org/.

Run `dot -Tpng <(zigmod explain --locked --format dot) -o explain.png` to generate the image.

<img width="1781" height="443" alt="Image" src="https://github.com/user-attachments/assets/217c5855-537e-4a93-ba49-b5fe6f78cdd2" />
