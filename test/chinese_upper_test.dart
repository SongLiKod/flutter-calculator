import 'package:flutter_test/flutter_test.dart';
import 'package:neon_calculator/calculator/engine.dart';

void main() {
  test('人民币大写：整数、零规则与进位单位', () {
    expect(toChineseUpper('0'), '零元整');
    expect(toChineseUpper('56'), '伍拾陆元整');
    expect(toChineseUpper('15'), '壹拾伍元整');
    expect(toChineseUpper('1005'), '壹仟零伍元整');
    expect(toChineseUpper('10500'), '壹万零伍佰元整');
    expect(toChineseUpper('10000005'), '壹仟万零伍元整');
    expect(toChineseUpper('10001000'), '壹仟万零壹仟元整');
    expect(toChineseUpper('1000000005'), '壹拾亿零伍元整');
    expect(toChineseUpper('101000001'), '壹亿零壹佰万零壹元整');
    expect(
      toChineseUpper('1234567890.5'),
      '壹拾贰亿叁仟肆佰伍拾陆万柒仟捌佰玖拾元伍角',
    );
    expect(
      toChineseUpper('999999999999'),
      '玖仟玖佰玖拾玖亿玖仟玖佰玖拾玖万玖仟玖佰玖拾玖元整',
    );
  });

  test('人民币大写：小数、零衔接与负数', () {
    expect(toChineseUpper('56146.5'), '伍万陆仟壹佰肆拾陆元伍角');
    expect(toChineseUpper('100.5'), '壹佰元伍角');
    expect(toChineseUpper('100.55'), '壹佰元伍角伍分');
    expect(toChineseUpper('100.05'), '壹佰元零伍分');
    expect(toChineseUpper('100.005'), '壹佰元零伍厘');
    expect(toChineseUpper('5.00'), '伍元整');
    expect(toChineseUpper('0.5'), '伍角');
    expect(toChineseUpper('0.05'), '伍分');
    expect(toChineseUpper('-42.3'), '负肆拾贰元叁角');
    // 超过 2 位小数逐位续写（厘毫丝忽微纤沙尘），不四舍五入
    expect(
      toChineseUpper('0.3333333333'),
      '叁角叁分叁厘叁毫叁丝叁忽叁微叁纤叁沙叁尘',
    );
    // 科学计数法等无法逐位转换的输入原样返回
    expect(toChineseUpper('1e+15'), '1e+15');
    expect(toChineseUpper('-1.5e-10'), '-1.5e-10');
  });
}
