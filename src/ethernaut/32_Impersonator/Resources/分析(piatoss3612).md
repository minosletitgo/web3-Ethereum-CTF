# [Ethernaut] 32. Impersonator

## **1\. 문제**
- https://ethernaut.openzeppelin.com/level/32

SlockDotIt’s new product, **ECLocker**, integrates IoT gate locks with Solidity smart contracts, utilizing Ethereum ECDSA for authorization. When a valid signature is sent to the lock, the system emits an Open event, unlocking doors for the authorized controller. SlockDotIt has hired you to assess the security of this product before its launch. Can you compromise the system in a way that anyone can open the door?

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "openzeppelin-contracts-08/access/Ownable.sol";

// SlockDotIt ECLocker factory
contract Impersonator is Ownable {
    uint256 public lockCounter;
    ECLocker[] public lockers;

    event NewLock(address indexed lockAddress, uint256 lockId, uint256 timestamp, bytes signature);

    constructor(uint256 _lockCounter) {
        lockCounter = _lockCounter;
    }

    function deployNewLock(bytes memory signature) public onlyOwner {
        // Deploy a new lock
        ECLocker newLock = new ECLocker(++lockCounter, signature);
        lockers.push(newLock);
        emit NewLock(address(newLock), lockCounter, block.timestamp, signature);
    }
}

contract ECLocker {
    uint256 public immutable lockId;
    bytes32 public immutable msgHash;
    address public controller;
    mapping(bytes32 => bool) public usedSignatures;

    event LockInitializated(address indexed initialController, uint256 timestamp);
    event Open(address indexed opener, uint256 timestamp);
    event ControllerChanged(address indexed newController, uint256 timestamp);

    error InvalidController();
    error SignatureAlreadyUsed();

    /// @notice Initializes the contract the lock
    /// @param _lockId uinique lock id set by SlockDotIt's factory
    /// @param _signature the signature of the initial controller
    constructor(uint256 _lockId, bytes memory _signature) {
        // Set lockId
        lockId = _lockId;

        // Compute msgHash
        bytes32 _msgHash;
        assembly {
            mstore(0x00, "\x19Ethereum Signed Message:\n32") // 28 bytes
            mstore(0x1C, _lockId) // 32 bytes
            _msgHash := keccak256(0x00, 0x3c) //28 + 32 = 60 bytes
        }
        msgHash = _msgHash;

        // Recover the initial controller from the signature
        address initialController = address(1);
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, _msgHash) // 32 bytes
            mstore(add(ptr, 32), mload(add(_signature, 0x60))) // 32 byte v
            mstore(add(ptr, 64), mload(add(_signature, 0x20))) // 32 bytes r
            mstore(add(ptr, 96), mload(add(_signature, 0x40))) // 32 bytes s
            pop(
                staticcall(
                    gas(), // Amount of gas left for the transaction.
                    initialController, // Address of `ecrecover`.
                    ptr, // Start of input.
                    0x80, // Size of input.
                    0x00, // Start of output.
                    0x20 // Size of output.
                )
            )
            if iszero(returndatasize()) {
                mstore(0x00, 0x8baa579f) // `InvalidSignature()`.
                revert(0x1c, 0x04)
            }
            initialController := mload(0x00)
            mstore(0x40, add(ptr, 128))
        }

        // Invalidate signature
        usedSignatures[keccak256(_signature)] = true;

        // Set the controller
        controller = initialController;

        // emit LockInitializated
        emit LockInitializated(initialController, block.timestamp);
    }

    /// @notice Opens the lock
    /// @dev Emits Open event
    /// @param v the recovery id
    /// @param r the r value of the signature
    /// @param s the s value of the signature
    function open(uint8 v, bytes32 r, bytes32 s) external {
        address add = _isValidSignature(v, r, s);
        emit Open(add, block.timestamp);
    }

    /// @notice Changes the controller of the lock
    /// @dev Updates the controller storage variable
    /// @dev Emits ControllerChanged event
    /// @param v the recovery id
    /// @param r the r value of the signature
    /// @param s the s value of the signature
    /// @param newController the new controller address
    function changeController(uint8 v, bytes32 r, bytes32 s, address newController) external {
        _isValidSignature(v, r, s);
        controller = newController;
        emit ControllerChanged(newController, block.timestamp);
    }

    function _isValidSignature(uint8 v, bytes32 r, bytes32 s) internal returns (address) {
        address _address = ecrecover(msgHash, v, r, s);
        require (_address == controller, InvalidController());

        bytes32 signatureHash = keccak256(abi.encode([uint256(r), uint256(s), uint256(v)]));
        require (!usedSignatures[signatureHash], SignatureAlreadyUsed());

        usedSignatures[signatureHash] = true;

        return _address;
    }
}
```

___

## **2\. 문제 해결 조건 확인**

> 누구나 **ECLocker**의 Open 이벤트를 발생시킬 수 있도록 시스템을 손상시켜라.

ECLocker의 Open 이벤트를 발생시키려면 먼저 open 함수를 실행해야 하며 인자로 주어진 (v, r, s)가 \_isValidSignature 함수를 통해 유효한 서명이라는 것이 검증되어야 합니다.

```solidity
function open(uint8 v, bytes32 r, bytes32 s) external {
    address add = _isValidSignature(v, r, s);
    emit Open(add, block.timestamp);
}
```

\_isValidSignature 함수는 먼저 ecrecover 내장 함수를 통해 (v, r, s)가 msgHash에 대한 올바른 서명인지 검증하고, 복원된 서명자의 주소를 가져옵니다. 그리고 서명자의 주소가 controller와 동일한지 검사합니다. 만약 동일하지 않으면 InvalidController 오류를 내보냅니다. 동일한 경우에는 서명에 대한 해시(signatureHash)를 생성하여 이미 사용한 적이 있는 서명인지를 확인한 뒤, 이미 사용한 서명의 경우에는 SignatureAlreadyUsed 오류를 내보냅니다. 사용되지 않은 서명은 usedSignatures에 저장한 뒤, 최종적으로 서명자의 주소를 반환합니다.

```solidity
bytes32 public immutable msgHash;
address public controller;
mapping(bytes32 => bool) public usedSignatures;

function _isValidSignature(uint8 v, bytes32 r, bytes32 s) internal returns (address) {
    address _address = ecrecover(msgHash, v, r, s);
    require(_address == controller, InvalidController());

    bytes32 signatureHash = keccak256(
        abi.encode([uint256(r), uint256(s), uint256(v)])
    );
    require(!usedSignatures[signatureHash], SignatureAlreadyUsed());

    usedSignatures[signatureHash] = true;

    return _address;
}
```

그렇다면 '누구나' open 함수를 정상적으로 실행시킬 수 있도록 하려면 어떤 부분을 건드려야 할까요?

우리는 **controller를 'address(0)'으로 변경**해야 합니다. 그 이유는 [ecrecover 함수](https://www.evm.codes/precompiled?fork=cancun#0x01)에 있습니다. ecrecover는 서명자의 주소를 복구할 수 없거나 실행에 필요한 가스가 부족한 경우, 어떤 데이터도 반환하지 않습니다. 그러나 함수 실행 자체가 revert(트랜잭션 실행이 취소됨) 되는 것이 아니기 때문에 비어있는 메모리에서 반환 데이터를 읽어 들이게 됩니다. 따라서 \_address에는 0x0이 저장되고 결과적으로 \_address는 address(0)가 됩니다.

![](Ethernaut%2032.%20Impersonator/img.png)

즉, controller를 address(0)으로 변경하면 (v, r, s) 서명값이 유효하지 않더라도 누구나 open 함수를 문제없이 실행할 수 있게 됩니다!

controller를 address(0)으로 변경하려면 changeController 함수를 실행해야 합니다. 이때도 서명자가 기존의 controller이며 사용되지 않은 (v, r, s) 값을 사용해 \_isValidSignature 함수를 통과해야만 합니다.

```solidity
function changeController(uint8 v, bytes32 r, bytes32 s, address newController) external {
    _isValidSignature(v, r, s);
    controller = newController;
    emit ControllerChanged(newController, block.timestamp);
}
```

문제 해결 과정을 정리해 보면 다음과 같습니다.

1.  msgHash에 대한 유효한 (v, r, s) 서명값을 찾아야 한다. 이때 서명자는 controller여야 한다.
2.  changeController 함수를 호출하여 controller를 address(0)으로 변경한다.

그럼 이제 문제는 한 가지로 좁혀졌습니다. **controller의 비밀키를 모르는데 어떻게 유효한 서명을 생성할 수 있을까요?**

___

## **3\. 서명 가변성 (Signature Malleability)**

### **ECDSA 서명의 기본 구조**

이더리움에서 ECDSA 서명은 다음 세 가지 구성 요소로 이루어져 있습니다:

1.  **r**: 서명 생성 시 사용된 타원 곡선 점의 x좌표에서 유도된 값
2.  **s**: 서명 생성 과정에서 사용된 비밀값과 메시지 해시를 기반으로 계산된 값
3.  **v**: 복구 식별자(Recovery Identifier)로, 서명으로부터 공개 키를 복구할 때 사용되는 추가 정보. 주로 27 또는 28 값을 가집니다.

### **서명 가변성**

이더리움에서 사용하는 ECDSA 서명 방식에는 서명 데이터를 약간 변경하여 기존 서명을 무효화시키지 않고도 유효한 새로운 서명을 만들어낼 수 있다는 취약점이 존재합니다. 그것도 비밀키를 알지 못한 상태에서도!

왜 이런 취약점이 존재하는가에 대해서는 타원곡선의 모양을 보시면 쉽게 이해할 수 있습니다. 아래의 곡선이 그래도 서명에 적용되는 것은 아니지만, 곡선이 x축에 대칭한다라는 것만 기억하시면 좋을 것 같아요. **곡선이 x축에 대칭**하기 때문에, x와 매핑되는 y값은 두 개가 존재합니다. 그렇기 때문에 서명 (r, s)에서 s를 x축에 반전시킨 **(r, -s)도 유효한 서명**으로 간주됩니다.

![](Ethernaut%2032.%20Impersonator/img.1.png)

y^2  = x^3  + 7

> **예상 질문: 아니, (r, s)는 타원곡선 위의 점이 아니잖아요?**

맞습니다. (r, s)는 타원곡선 위의 점이 아닌 스칼라 값입니다. 그러나 **타원곡선의 대칭성**은 여전히 유효하게 적용됩니다.

### **왜 s 값을 -s로 변경해도 서명이 유효한가?**

타원곡선 secp256k1에서 서명 (r, s)는 다음 수식을 만족합니다.

**s ≡ k<sup>-1</sup>(z + re) mod n**

여기서:

-   k: 임의의 비밀값
-   z: 메시지 해시
-   e: 서명자의 비밀키
-   n: 생성점 G로 생성한 유한순환군의 위수

만약 s 값을  n - s로 변경하면:

**s′ **≡** n - s **≡ -s mod n**** 

이를 위의 수식에 대입하면:

****s′** ≡ k<sup>-1</sup>(-z - re) mod n**

로 표현될 수 있습니다. 즉, n - s도 k, z, r, e, n을 사용해 계산될 수 있는 유효한 값인 것입니다. 이는 타원 곡선의 대칭성 때문에 가능한 것입니다. 그렇다면 s만 n - s로 변경하면 문제가 해결될까요?

### **s를 n - s로 변경하는 테스트**

아래의 코드는 실제 문제에서 사용되는 msgHash, v, r, s와 위수 n을 사용해 newS(n - s)를 구하고, (v, r, s)로부터 복원된 서명자 주소와 (v, r, newS)로부터 복원된 서명자의 주소가 동일한지 테스트하는 코드입니다.

```solidity
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";

contract SignatureMalleabilityTest is Test {
    bytes32 msgHash =
        0xf413212ad6f041d7bf56f97eb34b619bf39a937e1c2647ba2d306351c6d34aae;
    bytes32 n =
        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141;
    uint8 v = 0x1b; // 27
    bytes32 r =
        0x1932cb842d3e27f54f79f7be0289437381ba2410fdefbae36850bee9c41e3b91;
    bytes32 s =
        0x78489c64a0db16c40ef986beccc8f069ad5041e5b992d76fe76bba057d9abff2;

    function setUp() public {}

    function test_SubtractS() public {
        address originalAddr = ecrecover(msgHash, v, r, s);

        bytes32 newS = bytes32(uint256(n) - uint256(s));

        address newAddr = ecrecover(msgHash, v, r, newS);

        assertEq(originalAddr, newAddr);
    }
}
```

이 테스트를 실행해보면 다음과 같이 실패합니다. (v, r, s)로부터 복원된 주소와 (v, r, newS)로부터 복원된 주소가 다르군요! 도대체 무엇이 문제일까요?

```shell
forge test --mc SignatureMalleabilityTest -vvvv
[⠊] Compiling...
No files changed, compilation skipped

Ran 1 test for testsignature.t.sol:SignatureMalleabilityTest
[FAIL: assertion failed: 0x42069d82D9592991704e6E41BF2589a76eAd1A91 != 0x84165C5E6aD5ACa866b74f38fBe93C99AbAB5031] test_SubtractS() (gas: 20767)
Traces:
  [143] SignatureMalleabilityTest::setUp()
    └─ ← [Stop] 

  [20767] SignatureMalleabilityTest::test_SubtractS()
    ├─ [3000] PRECOMPILES::ecrecover(0xf413212ad6f041d7bf56f97eb34b619bf39a937e1c2647ba2d306351c6d34aae, 27, 11397568185806560130291530949248708355673262872727946990834312389557386886033, 54405834204020870944342294544757609285398723182661749830189277079337680158706) [staticcall]
    │   └─ ← [Return] 0x00000000000000000000000042069d82d9592991704e6e41bf2589a76ead1a91
    ├─ [3000] PRECOMPILES::ecrecover(0xf413212ad6f041d7bf56f97eb34b619bf39a937e1c2647ba2d306351c6d34aae, 27, 11397568185806560130291530949248708355673262872727946990834312389557386886033, 61386255033295324479228690463930298567438841096413154552415886062180481335631) [staticcall]
    │   └─ ← [Return] 0x00000000000000000000000084165c5e6ad5aca866b74f38fbe93c99abab5031
    ├─ [0] VM::assertEq(0x42069d82D9592991704e6E41BF2589a76eAd1A91, 0x84165C5E6aD5ACa866b74f38fBe93C99AbAB5031) [staticcall]
    │   └─ ← [Revert] assertion failed: 0x42069d82D9592991704e6E41BF2589a76eAd1A91 != 0x84165C5E6aD5ACa866b74f38fBe93C99AbAB5031
    └─ ← [Revert] assertion failed: 0x42069d82D9592991704e6E41BF2589a76eAd1A91 != 0x84165C5E6aD5ACa866b74f38fBe93C99AbAB5031

Suite result: FAILED. 0 passed; 1 failed; 0 skipped; finished in 649.71µs (426.17µs CPU time)

Ran 1 test suite in 120.83ms (649.71µs CPU time): 0 tests passed, 1 failed, 0 skipped (1 total tests)

Failing tests:
Encountered 1 failing test in testsignature.t.sol:SignatureMalleabilityTest
[FAIL: assertion failed: 0x42069d82D9592991704e6E41BF2589a76eAd1A91 != 0x84165C5E6aD5ACa866b74f38fBe93C99AbAB5031] test_SubtractS() (gas: 20767)

Encountered a total of 1 failing tests, 0 tests succeeded
```

### **공개키 복구**

앞서 테스트에서 newS를 사용해서 주소를 복구했더니 완전히 다른 주소가 나왔습니다. 공개키를 복구하는 수식은 다음과 같습니다.

**P = r<sup>-1</sup> (sR - zG)**

**P**′** = r<sup>-1</sup> (sR′ - zG)**

여기서:

-   r: 서명 생성 시 사용된 타원 곡선 점의 x좌표에서 유도된 값
-   s: 서명 생성 과정에서 사용된 비밀값과 메시지 해시를 기반으로 계산된 값
-   R, R′: x좌표인 r값을 사용해 타원곡선에서 구할 수 있는 두 개의 점. R이 처음으로 구한 (x, y)라면 R′은 (x, n - y)
-   z: 메시지 해시
-   G: 타원 곡선 생성점

여기서 R과 R′은 다음과 같이 계산할 수 있습니다.

```go
package main

import (
"fmt"
"math/big"
)

var P = big.NewInt(0).Sub(
big.NewInt(0).Sub(
big.NewInt(0).Exp(big.NewInt(2), big.NewInt(256), nil),
big.NewInt(0).Exp(big.NewInt(2), big.NewInt(32), nil)),
big.NewInt(977))

func main() {
r, _ := big.NewInt(0).SetString("1932cb842d3e27f54f79f7be0289437381ba2410fdefbae36850bee9c41e3b91", 16)

        // y^2 = x^3 + 7 (mod P)
ySquared := big.NewInt(0).Exp(r, big.NewInt(3), P)
ySquared.Add(ySquared, big.NewInt(7))
ySquared.Mod(ySquared, P)

exponent := new(big.Int).Add(P, big.NewInt(1)) // P + 1
exponent.Div(exponent, big.NewInt(4))          // (P + 1) / 4
y := new(big.Int).Exp(ySquared, exponent, P)   // y = ySquared ^ ((P + 1) / 4) (mod P) -> y 값 구하기

yAlt := new(big.Int).Sub(P, y) // yAlt = P - y

fmt.Printf("R: (%s, %s)\n", r.Text(16), y.Text(16))
fmt.Printf("R′: (%s, %s)\n", r.Text(16), yAlt.Text(16))
}
```

```shell
$ go run .
R: (1932cb842d3e27f54f79f7be0289437381ba2410fdefbae36850bee9c41e3b91, d5b8cb5566ffa2f8934c782cd348548ff11a19d7718b5beff7eb55bb42111ef4)
R′: (1932cb842d3e27f54f79f7be0289437381ba2410fdefbae36850bee9c41e3b91, 2a4734aa99005d076cb387d32cb7ab700ee5e6288e74a4100814aa43bdeedd3b)
```

그리고 각각의 점을 사용해 도출해 낸 공개키는 다음과 같습니다.

-   R로부터 도출된 공개키: 0x42069d82D9592991704e6E41BF2589a76eAd1A91
-   R′로부터 도출된 공개키: 0x84165C5E6aD5ACa866b74f38fBe93C99AbAB5031

x 좌푯값 r로부터 도출되는 타원곡선 위의 점은 R과 R′ 두 개가 있습니다. 그리고 각각의 점을 사용해 구한 공개키 또한 P와 P′ 두 개가 있지요. 그러면 두 개의 공개키가 모두 유효하지는 않을 테고, 어느 공개키가 서명자의 공개키인지 무엇을 통해 알 수 있을까요?

### **v값과 y좌표의 부호**

v 값은 공개 키 복구 과정에서 **서명으로부터 정확한 공개 키를 식별하는 데 사용**됩니다. 이는 앞서 살펴본 바와 같이 서명으로부터 공개 키를 복구할 때 발생할 수 있는 두 가지 가능한 해 중 하나를 선택하는 데 필수적입니다.

v값은 기본 형태로 27 또는 28을 가집니다. EIP-155를 적용하여 체인 ID를 포함할 수도 있는데 이는 주제에서 벗어난 이야기이므로 제외하겠습니다.

-   27인 경우: y좌표가 짝수인 점을 선택
-   28인 경우: y좌표가 홀수인 점을 선택

이에 따르면 문제에서 사용된 v값은 27이므로, R(y가 짝수인 점)을 사용해 도출된 공개키 '0x42069d82D9592991704e6E41BF2589a76eAd1A91'가 서명자의 공개키로서 복원되게 됩니다.

### **s를 n - s로 변경했을 때 v는?**

그런데 앞서 실행해 본 테스트에서는 (v, r, n - s)를 사용해서 공개키를 복원했는데 '0x84165C5E6aD5ACa866b74f38fBe93C99AbAB5031'가 반환된 것을 확인할 수 있습니다. 다음 식을 다시 한번 확인해 봅시다.

**P = r<sup>-1</sup> (sR - zG)**

여기서 s에 -s를 대입해 보면,

**r<sup>-1</sup> (-sR - zG) = **r<sup>-1</sup> (sR**′** - zG) = **P**′********

R의 y 부호가 반전되어 결과적으로 y값이 홀수인 R′을 사용해 공개키를 도출하게 됩니다.

우리는 \_isValidSignature 함수를 통과하기 위해 P가 필요하므로 -s를 사용하면서 P를 결과로 얻으려면,

**r<sup>-1</sup> (-sR******′****** - zG) = **r<sup>-1</sup> (sR \- zG) = **P******

y값이 홀수인 R′을 사용해야 합니다. 즉, -s를 사용해 서명을 검증하려면 v값이 27이 아닌 28이 되어야 한다는 것입니다.

### **수정된 테스트**

v값을 28로 변경하여 테스트를 실행해 봅시다.

```solidity
function test_SubtractS() public {
    address originalAddr = ecrecover(msgHash, v, r, s);

    uint8 newV = 27 + (1 - (v - 27));
    bytes32 newS = bytes32(uint256(n) - uint256(s));

    address newAddr = ecrecover(msgHash, newV, r, newS);

    assertEq(originalAddr, newAddr);
}
```

```shell
forge test --mc SignatureMalleabilityTest -vvvv
[⠊] Compiling...
No files changed, compilation skipped

Ran 1 test for testsignature.t.sol:SignatureMalleabilityTest
[PASS] test_SubtractS() (gas: 21055)
Traces:
  [21055] SignatureMalleabilityTest::test_SubtractS()
    ├─ [3000] PRECOMPILES::ecrecover(0xf413212ad6f041d7bf56f97eb34b619bf39a937e1c2647ba2d306351c6d34aae, 27, 11397568185806560130291530949248708355673262872727946990834312389557386886033, 54405834204020870944342294544757609285398723182661749830189277079337680158706) [staticcall]
    │   └─ ← [Return] 0x00000000000000000000000042069d82d9592991704e6e41bf2589a76ead1a91
    ├─ [3000] PRECOMPILES::ecrecover(0xf413212ad6f041d7bf56f97eb34b619bf39a937e1c2647ba2d306351c6d34aae, 28, 11397568185806560130291530949248708355673262872727946990834312389557386886033, 61386255033295324479228690463930298567438841096413154552415886062180481335631) [staticcall]
    │   └─ ← [Return] 0x00000000000000000000000042069d82d9592991704e6e41bf2589a76ead1a91
    ├─ [0] VM::assertEq(0x42069d82D9592991704e6E41BF2589a76eAd1A91, 0x42069d82D9592991704e6E41BF2589a76eAd1A91) [staticcall]
    │   └─ ← [Return] 
    └─ ← [Stop] 

Suite result: ok. 1 passed; 0 failed; 0 skipped; finished in 639.04µs (412.42µs CPU time)

Ran 1 test suite in 120.38ms (639.04µs CPU time): 1 tests passed, 0 failed, 0 skipped (1 total tests)
```

![](https://img1.daumcdn.net/thumb/R1280x0/?scode=mtistory2&fname=https%3A%2F%2Fblog.kakaocdn.net%2Fdna%2FNfvo6%2FbtsKTUgFOqY%2FAAAAAAAAAAAAAAAAAAAAAFr07qZ-VIaq7Z2JHflJPGPM22OTpcte85mwmd8ktyj8%2Fimg.png%3Fcredential%3DyqXZFxpELC7KVnFOS48ylbz2pIh7yKj8%26expires%3D1767193199%26allow_ip%3D%26allow_referer%3D%26signature%3DZ3apAOfonsI9K12CpzFs7LO%252Flpg%253D)

성공!

___

## **4\. 공격**

### **스크립트 작성**

```solidity
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {Script, console} from "forge-std/Script.sol";
import {Impersonator, ECLocker} from "src/32.Impersonator.sol";

contract ImpersonatorScript is Script {
    bytes32 N =
        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        address instanceAddr = 0x1a2942bED6e1b02990C01c7c48836bDe94fC5372;

        Impersonator impersonator = Impersonator(instanceAddr);
        ECLocker locker = impersonator.lockers(0);

        uint8 v = 0x1b; // 27
        bytes32 r = 0x1932cb842d3e27f54f79f7be0289437381ba2410fdefbae36850bee9c41e3b91;
        bytes32 s = 0x78489c64a0db16c40ef986beccc8f069ad5041e5b992d76fe76bba057d9abff2;

        uint8 newV = 27 + (1 - (v - 27));
        bytes32 newS = bytes32(uint256(N) - uint256(s));

        locker.changeController(newV, r, newS, address(0));

        vm.stopBroadcast();
    }
}
```

### **스크립트 실행**

```shell
forge script script/32.Impersonator.s.sol --account dev --sender 0x965B0E63e00E7805569ee3B428Cf96330DFc57EF --rpc-url sepolia --broadcast -vvvv
[⠊] Compiling...
No files changed, compilation skipped
Traces:
  [49730] ImpersonatorScript::run()
    ├─ [0] VM::startBroadcast()
    │   └─ ← [Return] 
    ├─ [4645] 0xC0231b5c1926a3c41AB6e75C131DC39A2858aBbB::lockers(0) [staticcall]
    │   └─ ← [Return] 0x00C51350C2EE06551C46D9993EdF5D80BECFa2D5
    ├─ [33401] 0x00C51350C2EE06551C46D9993EdF5D80BECFa2D5::changeController(28, 0x1932cb842d3e27f54f79f7be0289437381ba2410fdefbae36850bee9c41e3b91, 0x87b7639b5f24e93bf106794133370f950d5e9b00f5b5c8cbd866a487529b814f, 0x0000000000000000000000000000000000000000)
    │   ├─ [3000] PRECOMPILES::ecrecover(0xf413212ad6f041d7bf56f97eb34b619bf39a937e1c2647ba2d306351c6d34aae, 28, 11397568185806560130291530949248708355673262872727946990834312389557386886033, 61386255033295324479228690463930298567438841096413154552415886062180481335631) [staticcall]
    │   │   └─ ← [Return] 0x00000000000000000000000042069d82d9592991704e6e41bf2589a76ead1a91
    │   ├─ emit ControllerChanged(newController: 0x0000000000000000000000000000000000000000, timestamp: 1732360560 [1.732e9])
    │   └─ ← [Stop] 
    ├─ [0] VM::stopBroadcast()
    │   └─ ← [Return] 
    └─ ← [Stop] 


Script ran successfully.

## Setting up 1 EVM.
==========================
Simulated On-chain Traces:

  [33401] 0x00C51350C2EE06551C46D9993EdF5D80BECFa2D5::changeController(28, 0x1932cb842d3e27f54f79f7be0289437381ba2410fdefbae36850bee9c41e3b91, 0x87b7639b5f24e93bf106794133370f950d5e9b00f5b5c8cbd866a487529b814f, 0x0000000000000000000000000000000000000000)
    ├─ [3000] PRECOMPILES::ecrecover(0xf413212ad6f041d7bf56f97eb34b619bf39a937e1c2647ba2d306351c6d34aae, 28, 11397568185806560130291530949248708355673262872727946990834312389557386886033, 61386255033295324479228690463930298567438841096413154552415886062180481335631) [staticcall]
    │   └─ ← [Return] 0x00000000000000000000000042069d82d9592991704e6e41bf2589a76ead1a91
    ├─ emit ControllerChanged(newController: 0x0000000000000000000000000000000000000000, timestamp: 1732360572 [1.732e9])
    └─ ← [Stop] 


==========================

Chain 11155111

Estimated gas price: 26.229131761 gwei

Estimated total gas used for script: 74506

Estimated amount required: 0.001954227690985066 ETH

==========================
Enter keystore password:

##### sepolia
✅  [Success] Hash: 0xeddbae7a3940d18102ad7efd68dd4b645f391a45d701da42682daf46ca9ad2f2
Block: 7135779
Paid: 0.000706945324998745 ETH (50945 gas * 13.876638041 gwei)

✅ Sequence #1 on sepolia | Total Paid: 0.000706945324998745 ETH (50945 gas * avg 13.876638041 gwei)
                                                                                                                                                                                                           

==========================

ONCHAIN EXECUTION COMPLETE & SUCCESSFUL.

Transactions saved to: /ethernaut/broadcast/32.Impersonator.s.sol/11155111/run-latest.json

Sensitive values saved to: /ethernaut/cache/32.Impersonator.s.sol/11155111/run-latest.json
```

### **제출**

![](https://img1.daumcdn.net/thumb/R1280x0/?scode=mtistory2&fname=https%3A%2F%2Fblog.kakaocdn.net%2Fdna%2FPP77u%2FbtsKTYJOKtW%2FAAAAAAAAAAAAAAAAAAAAAMJbuDmP28j6x7pSecaYgbkA9IuOhNqCxh9exTSIdXT9%2Fimg.png%3Fcredential%3DyqXZFxpELC7KVnFOS48ylbz2pIh7yKj8%26expires%3D1767193199%26allow_ip%3D%26allow_referer%3D%26signature%3Dc6IkPEHF4wDUMErK7Uei3awuIxo%253D)

___

## **5\. 서명 가변성으로 인한 보안 문제를 방지하는 방법**

### **안전한 OpenZeppelin ECDSA 라이브러리 사용하기**

이 문제의 의도는 결국 '우리 라이브러리 사용해라' 입니다.

[

openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol at 448efeea6640bbbc09373f03fbc9c88e280147ba · OpenZeppelin/openze

OpenZeppelin Contracts is a library for secure smart contract development. - OpenZeppelin/openzeppelin-contracts

github.com



](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/448efeea6640bbbc09373f03fbc9c88e280147ba/contracts/utils/cryptography/ECDSA.sol)![](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/448efeea6640bbbc09373f03fbc9c88e280147ba/contracts/utils/cryptography/ECDSA.sol)

그래서 뭐가 어떻게 다르냐? 아래 코드를 봅시다. 코드상에서 ecrecover 함수를 호출하기 전에 s값에 대한 간단한 유효성 검사를 진행합니다. 무엇을 검사하느냐? s 값이 위수 n을 반으로 나눈 값 n/2보다 큰지를 확인합니다. 만약 s > n/2 라면 유효하지 않은 서명으로 간주하고 오류를 내보내게 됩니다. 이런 식으로 s가 n/2보다 작거나 같도록 강제함으로써 서명 가변성을 사용해 서명을 재사용하는 것을 방지하려고 한 것입니다. 물론 비용은 더 들겠지만 보안을 위해서라면 그 정도는 감수가 필요하겠지요.

```solidity
function tryRecover(
    bytes32 hash,
    uint8 v,
    bytes32 r,
    bytes32 s
) internal pure returns (address recovered, RecoverError err, bytes32 errArg) {
    // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
    // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
    // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
    // signatures from current libraries generate a unique signature with an s-value in the lower half order.
    //
    // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
    // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
    // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
    // these malleable signatures as well.
    if (
        uint256(s) >
        0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0
    ) {
        return (address(0), RecoverError.InvalidSignatureS, s);
    }

    // If the signature is valid (and not malleable), return the signer address
    address signer = ecrecover(hash, v, r, s);
    if (signer == address(0)) {
        return (address(0), RecoverError.InvalidSignature, bytes32(0));
    }

    return (signer, RecoverError.NoError, bytes32(0));
}
```
