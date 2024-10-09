/**
 * 实践 POW， 编写程序（编程语言不限）用自己的昵称 + nonce，不断修改nonce 进行 sha256 Hash 运算：
 *
 * 直到满足 4 个 0 开头的哈希值，打印出花费的时间、Hash 的内容及Hash值。
 * 再次运算直到满足 5 个 0 开头的哈希值，打印出花费的时间、Hash 的内容及Hash值。
 */

/**
 * 1. nickName 昵称是固定的
 *    nonce: 可以任意字母，数字，长度任意
 *    字符串拼接str: nickName + nonce
 *    使用生成hash的库: 对str 进行hash
 * 2. 对str进行验证，
 *    打印开始时间
 *    对str进行截取前4个字符，fourChar，if (fourChar === '000')
 *    打印结束时间
 *    计算时间差，Hash的内容，nonce的值
 * 3. 对str进行验证
 */

/**
 * @param nickName string
 * @param nonce string
 * @param digit number
 * @constructor
 */
const sha256 = require('crypto-js/sha256');
function generateNonce() {
  const characters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
  const length = Math.floor(Math.random() * 100) + 1; // 随机长度，范围从 1 到 100
  let nonce = '';

  for (let i = 0; i < length; i++) {
    const randomIndex = Math.floor(Math.random() * characters.length);
    nonce += characters[randomIndex];
  }

  return nonce;
}

function powVerify(nickName, nonce, digit = 4) {
  let str = nickName + nonce
  const hash = sha256(str).toString(); //生成的哈希值转换为字符串
  const fourChar = hash.slice(0,digit)
  if (fourChar.slice(0,digit) === '0000'){ // slice 会返回一个新的字符串
    return {
      success: true,
      hash: hash
    }
  }
  return {
    success: false,
    hash: hash
  }
}
function test () {
  const nickName = 'sy-sophie'
  let nonce;
  let result;
  const startDate = new Date(); // 开始时间
  do {
    nonce = generateNonce();
    result = powVerify(nickName, nonce);
  }while (!result.success) // 验证不通过，则继续生成nonce

  const endDate = new Date(); // 结束时间


  console.log('验证通过！');
  console.log('Hash 的内容：', result.hash);
  console.log('Nonce 的值：', nonce);
  console.log('时间差为：', endDate - startDate, '毫秒');

  return { hash: result.hash, nonce: nonce };
}
test();

module.exports = {
  test,
}
