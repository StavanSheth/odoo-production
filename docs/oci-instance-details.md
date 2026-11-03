# Oracle Cloud Infrastructure (OCI) Instance Configuration

Recorded on: `2026-11-04`

---

## 1. Basic Information
| Property | Value |
|---|---|
| **Instance Name** | `instance-20261104-0059` |
| **Compartment** | `stavanasheth (root)` |
| **Availability Domain** | `AD-1` |
| **Capacity Type** | `on-demand` |
| **Fault Domain** | `Let Oracle choose the best fault domain` |

---

## 2. Image & Hardware Shape
| Property | Value |
|---|---|
| **Operating System** | `Oracle Linux 9` |
| **Image Build** | `2026.10.16-0` |
| **Default SSH User** | `opc` *(Oracle Linux default)* |
| **Shape** | `VM.Standard.A1.Flex` (Always Free Eligible) |
| **Hardware Specs** | 2 Core OCPU, 12 GB Memory, 2 Gbps network bandwidth |
| **Architecture** | ARM64 (`aarch64`) |

---

## 3. Networking Configuration
| Property | Value |
|---|---|
| **Virtual Cloud Network (VCN)** | `vcn-20261104-0121` |
| **Subnet** | `subnet-20261104-0121` (`10.0.0.0/24`) |
| **Private IPv4 Address** | Automatically assigned on creation |
| **Public IPv4 Address** | `No` *(Action Required: Enable Ephemeral Public IP for direct SSH access)* |
| **DNS Record** | Yes |
| **IPv6** | Disabled |

---

## 4. SSH Public Key
```text
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDNjosgOomMnJuOu7D1YREnvhMGZrIQY5J62i9sTFRN5tqS+7Axqsn7RTOUObOPIRpF4fwrm+uLV0eI0Y//jcFsYWwQriKpUO31obAj0+JLxhZBhEWL/ronmOX7y010NmztXp4XH8jzyjmQsdycHIHc5KZXStMNr3Ihjq3npW9pafdSBI94N78dop9XD57cGBQnmliItCHQrodEJYTFP3D7uYaiZRYL9To+FuHmpjk3paHeygP1IMRr/zxwTTsoH1eR25y6AqWygFkZvp+RQ5NJJ0M11UMNv+dWXh/o936HVExhfGlxQcfLBhOCmSv5Tezq+NM7QDaHmFQNxXisTGOH ssh-key-2026-11-03
```

---

## 5. Storage & Boot Volume
| Property | Value |
|---|---|
| **Boot Volume Size** | Default (~46.6 GB, within Always Free 200 GB limit) |
| **In-Transit Encryption** | Enabled |
| **Block Volumes** | None attached (using default boot volume) |
