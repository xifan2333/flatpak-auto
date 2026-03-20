<!-- 该文件由 scripts/build-readme.sh 自动生成，请勿手动编辑。 -->

# flatpak-auto

使用 GitHub Actions 自动维护可复用 Flatpak 仓库的工具集。

## 项目概览
- 通过 `products/<name>/upstream.sh` 检测各个上游项目的新版本。
- 从分散的上游项目下载 Flatpak release bundle。
- 将 bundle 导入统一的 OSTree 仓库。
- 生成共享的 `.flatpakrepo` 与每个产品对应的 `.flatpakref`。
- 发布到 `gh-pages`。

## 维护者
- xifan `<xifan2333@gmail.com>`

## 仓库信息
- Remote 名称：`xifan`
- 默认分支：`stable`
- Runtime 仓库：`https://flathub.org/repo/flathub.flatpakrepo`

## 产品列表
| Product | App ID | Description | Upstream | Version | Sync Status |
| --- | --- | --- | --- | --- | --- |
| `fcitx5-vinput` | `org.fcitx.Fcitx5.Addon.Vinput` | Offline voice input addon for Fcitx5 with optional OpenAI-compatible postprocess | `fcitx5-vinput` | pending | [![Sync Status](https://img.shields.io/github/actions/workflow/status/xifan2333/flatpak-auto/sync-and-publish.yml?branch=main&logo=github&label=sync)](https://github.com/xifan2333/flatpak-auto/actions/workflows/sync-and-publish.yml) |

元数据变更后可运行 `scripts/build-readme.sh` 重新生成 README。
