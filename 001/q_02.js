/**
 * 实践非对称加密 RSA（编程语言不限）：
 *
 * 先生成一个公私钥对
 * 用私钥对符合 POW 4个0开头的哈希值的 “昵称 + nonce” 进行私钥签名
 * 用公钥验证
 */

/**
 * 1. 利用库生成公钥私钥,使用EC(椭圆曲线)密钥对
 */
const { test } = require('./q_01')
const crypto = require('crypto');

// 生成 EC 公钥私钥对
const { publicKey, privateKey } = crypto.generateKeyPairSync('ec', {
    namedCurve: 'secp256k1', // 比特币和以太坊使用的曲线
    publicKeyEncoding: {
        type: 'spki',
        format: 'pem'
    },
    privateKeyEncoding: {
        type: 'pkcs8',
        format: 'pem'
    }
});

const result = test();
const hash = result.hash // 要加密的hash

// 使用私钥进行签名
const sign = crypto.createSign('SHA256'); // 创建签名对象
sign.update(hash); // 更新要签名的数据
sign.end();
const signature = sign.sign(privateKey, 'base64'); // 使用私钥生成签名
console.log('Signature:', signature);

// 使用公钥进行验证
const verify = crypto.createVerify('SHA256'); // 创建验证对象
verify.update(hash); // 更新要验证的数据
verify.end();
const isVerified = verify.verify(publicKey, signature, 'base64'); // 验证签名

console.log('Verification:', isVerified); // 输出验证结果
