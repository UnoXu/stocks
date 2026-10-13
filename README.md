# 持仓助手 · Stock Panel

一个跑在自己电脑上、手机浏览器能打开的小应用：**按比例算该买多少**、**一键买入并入账**、**随时看持仓比重和收益**。

跟踪四只标的：**VOO**、**伯克希尔 B（BRK.B）**、**苹果（AAPL）**、**拼多多（PDD）**。

**零依赖**——只用 Node 内置模块，不需要 `npm install`，不向任何第三方上传你的持仓数据。

---

## 跑起来（本机）

需要 Node 18+。

```bash
node server.mjs
```

Windows 上也可以双击 `start-server.cmd`（无提示）或 `start.bat`（出错会停住给你看）。

启动后控制台会打印访问地址，形如：

```
本机：      http://127.0.0.1:8787
局域网：    http://192.168.x.x:8787
访问口令：  xxxxxxxxxxx
数据文件：  .../state.json
```

- **电脑上**：打开 `http://127.0.0.1:8787`（本机免口令）
- **手机上**：先连同一个 WiFi，用 Safari 打开那个局域网地址，输入控制台打印的口令 → 分享 → 添加到主屏幕
- **想停止**：`Ctrl+C`，或双击 `stop.bat`

---

## 部署到云端（电脑关机也能用）

数据存到你自己的免费键值存储里，容器本身无状态，所以免费档重启/休眠都不会丢数据。

### 需要三个环境变量

| 变量 | 说明 |
|---|---|
| `KV_REST_URL` | 免费键值存储的 REST 地址（Upstash / Vercel KV 兼容协议） |
| `KV_REST_TOKEN` | 对应的 token |
| `STOCK_TOKEN` | **访问口令**，公网上必须设，否则谁拿到网址都能看你的持仓 |

> 不设 `KV_REST_URL` 时，数据存在本机 `state.json`（默认行为，适合本机使用）。
> `DATA_DIR` 可指定数据目录；`PORT` 可改端口（默认 8787，Docker 镜像里默认 8080）。

### 用 Docker

```bash
docker build -t stock-panel .
docker run -d --restart unless-stopped -p 8080:8080 \
  -e KV_REST_URL="你的URL" \
  -e KV_REST_TOKEN="你的TOKEN" \
  -e STOCK_TOKEN="你的口令" \
  stock-panel
```

### 平台部署

- `render.yaml` —— Render Blueprint（注意：Render 免费档现在要绑卡）
- `fly.toml` —— Fly.io
- 任何支持 Docker 的平台都可以，只要设上面三个环境变量

部署完成后自检：

```
https://你的地址/api/health
```

应该看到：

```json
{ "storage": "kv", "degraded": false, "auth": "on" }
```

- `storage` 是 `kv` → 云存储接上了
- `degraded` 是 `false` → 云存储正常
- `auth` 是 `on` → 口令保护生效（**公网上必须是 on**）

---

## 交易口径（可核对）

| 项 | 规则 |
|---|---|
| 最小交易单位 | **0.01 股**，向下取整（不超出你给的金额） |
| 手续费 | **买入金额 × 费率**，默认 **0.1%**，界面可改 |
| 手续费口径 | **另计**：你填的金额是「买多少钱的股票」 |
| 成本价 | **含手续费**摊进成本，所以「累计盈亏」是真实盈亏 |

```
股数     = floor(买入金额 ÷ 现价 ÷ 0.01) × 0.01
股票占用 = 股数 × 现价
手续费   = 买入金额 × 费率
实际扣款 = 股票占用 + 手续费
新成本价 = (原份额×原成本价 + 股票占用 + 手续费) ÷ (原份额 + 新份额)
```

- **当日盈亏** = `(现价 − 昨收) × 份额`
- **累计浮动盈亏** = `市值 − 份额 × 含费成本价`
- **持仓比重** = `该只市值 ÷ 全部市值合计`

---

## 行情来源

- 主源：腾讯行情 `qt.gtimg.cn`（GBK 编码，服务端代理，不依赖浏览器跨域）
- 备源：新浪行情 `hq.sinajs.cn`（只用来补腾讯拿不到的标的）
- 服务端缓存 1.5 秒，页面每 5 秒刷新一次；上游本身有约 1~3 分钟延迟，这是数据源的限制

某只拿不到价格时会保留上次成功价格并标「旧价」，**绝不会把缺价格当成 0**；此时该只不允许下单。

---

## 接口

| 方法 | 路径 | 作用 |
|---|---|---|
| GET | `/api/health` | 自检：存储后端、是否降级、口令是否开启 |
| GET | `/api/quotes` | 行情（`?force=1` 跳过缓存） |
| GET | `/api/state` | 配比 + 持仓 + 最近流水 |
| GET | `/api/holdings` | 算好的持仓视图与汇总 |
| POST | `/api/targets` | 保存总金额、配比、手续费率 |
| POST | `/api/positions` | 保存份额与成本价 |
| POST | `/api/buy` | `{symbol, amount}` 按实时价折算买入并入账 |
| POST | `/api/buy/reset-baseline` | 重置当日基准 |
| DELETE | `/api/buys/last` | 撤销最近一笔买入 |
| GET | `/api/export` | 导出完整数据（备份用） |
| POST | `/api/import` | 导入备份（整体覆盖） |

---

## 安全说明

- 数据存哪：默认本机 `state.json`；设了 `KV_REST_URL` 则存在你自己的键值存储里
- 口令：本机与 Tailscale 网段免密；局域网与公网需要口令
- 云存储临时不可用时**自动变只读**并拒绝写入，而不是静默丢数据
- `.gitignore` / `.dockerignore` 已排除 `state.json`、`.auth.txt`、备份目录
