## What Are (Custom) Placeholders and How to Use Them?

Placeholders can be considered **macros** or **predefined variables** that you can change in certain inputs **without modifying the final command**.

For example, we have many predefined placeholders, like `%wallet_address%`, which represents your currently selected wallet address.  
If you change your wallet in the **Wallets** menu, it gets updated in **Pools**, and then in **Miner Profiles**.

---

### ✅ Built-in Placeholders

#### 🔹 Pool Placeholders

- `%pool_protocol%` — Enables or disables SSL support for pools. Defined in the miner template as `pool_protocol{}`.
- `%pool_server%` — Pool hostname (e.g., `stratum.gettomine.com`). Does **not** include `stratum+tcp://`, `ssl://`, etc.
- `%pool_port%` — Numeric port of the pool server (e.g., `3098`).

**Examples**:

```
%pool_server%:%pool_port%
→ stratum.gettomine.com:3098

%pool_protocol%%pool_server%:%pool_port%

Example (no SSL):
→ stratum+tcp://stratum.gettomine.com:3098

Example (SSL):
→ stratum+ssl://stratum.gettomine.com:3098
```

---

#### 🔹 User Placeholders

- `%user%` — Expands to `%wallet_address%.%rig_name%%miner_id%`
- `%wallet_address%` — From Wallets → Address
- `%rig_name%` — From Rigs → Name
- `%miner_id%` — Miner instance index in multiminer setups
- `%password%` — Pool password (default: `x`)

**Example Values**:

```
wallets->address = 0x1234567891011121314151617181920212223
rigs->name = myRig1
```

**Example Command**:

```
%pool_protocol%%pool_server%:%pool_port% --user %user% --password %password%

→ stratum+tcp://stratum.gettomine.com:3098
--user 0x1234567891011121314151617181920212223.myRig1
--password x
```

---

#### 🔹 API Port Placeholder

- `%api_port%` — Port where the miner API listens (depends on miner, often user-defined).

---

### ✨ Custom Placeholders

Custom placeholders are user-defined values that can be injected into command-line arguments or preminer commands.

- Each custom placeholder has the `custom_` prefix.
- If you create one called `mythings`, it becomes `%custom_mythings%`.

#### 🔧 How to Use

1. **Create** a custom placeholder (can be empty).
2. **Edit** the Miner Profile:
   - Go to **Advanced**, and append `%custom_myplaceholder%` at the end of the miner arguments.
3. **Per-Rig Override**:
   - Go to **Rigs** → select rig → click ⚙️ **Rig Config**.
   - Navigate to **Placeholders** → **Custom Placeholders**.
   - Assign a value like `-d 0`.

Now that rig will have `-d 0` appended to its miner arguments. Others using the same profile will remain unaffected.

#### 💡 Why Use Custom Placeholders?

- Avoid creating duplicate miner profiles for small tweaks.
- Configure per-rig options like GPU targeting.
- Can be used for preminer scripts, testing, or command injection.
- Clean and flexible.

---

### 📸 Screenshots

![Profile](/imgs/custom1.png)  
![Profile](/imgs/custom2.png)  
![Profile](/imgs/custom3.png)

