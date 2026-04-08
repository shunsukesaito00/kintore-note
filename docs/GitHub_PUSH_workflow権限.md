# GitHub に push すると「workflow のスコープ」で拒否される場合

`.github/workflows/*.yml` を含むコミットを push すると、**Personal Access Token (classic)** に **`workflow` スコープ**がないと GitHub が拒否します。

## 対処

1. GitHub → **Settings** → **Developer settings** → **Personal access tokens**  
2. 使っているトークンを **Edit** し、**workflow** にチェックを入れて保存  
3. 再度 `git push`

または **SSH**（`git@github.com:...`）で push する（鍵認証なら通常この制限は出ません）。

参考: リモート URL を SSH にする例:

```bash
git remote set-url origin git@github.com:shunsukesaito00/kintore-note.git
```
