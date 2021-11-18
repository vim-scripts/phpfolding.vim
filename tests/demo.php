<?php
namespace app\tests;

// [NOT FOLDED]: blocks commented with //
// line 2
// line 3

// [NOT FOLDED]: include/require w/o docblock
include "a.php";
include "b.php";
require "c.php";
require "d.php";

// [FOLDED]: define w/ docblock
/**
 * @var string docblock for constant1
 */
define('constant1', '5');


// [FOLDED]: include/require w/ docblock
/**
 * Include dockbloc
 */
include "e.php";
/**
 * Require docblock
 */
require "f.php";


// [FOLDED]: use statements
use TestClass1;
use TestClass2;
use app\dummy\TestClass3;

// [FOLDED]: global function w/o docblock
function dummy_function_1($a, $b, $c) {
    if ($a) {
        return $b;
    }
    return $c;
}


// [FOLDED]: global function w/ docblock
/**
 * dummy_function_1
 *
 * @param mixed $a
 * @param mixed $b
 * @param mixed $c
 * @return void
 */
function dummy_function_2($a, $b, $c)
{
    if ($a) {
        return $b;
    }
    return $c;
}


// [NOT FOLDED]: global variable w/ docblock
/**
 * @var int docblock for a
 */
$a = 7;

// [NOT FOLDED]: class header w/o docblock
class Demo1
{
}

// [NOT FOLDED]: class header w/ docblock
/**
 * This is the docblock for Demo2
 *
 * @property string $test a test property
 */
class Demo2
{
    // [NOT FOLDED]: Constants w/o docblock
    const A1 = 'a1';
    const A2 = 'a2';

    // [FOLDED]: Constants w/ docblock
    /**
     * Docblock for B1
     */
    const B1 = 'b1';


    // [NOT FOLDED]: Variables w/o docblock
    public static $a1;
    protected $b1;
    private $c1;

    // [FOLDED]: Variables w/ docblock
    /**
     * @var mixed doc var a2
     */
    public $a2;
    /**
     * Multi line
     * docblock
     *
     * @var mixed var b2
     */
    protected $b2;
    /** @var mixed single line dockblock */
    private $c2;

    // [FOLDED]: Methods w/o docblock
    public static function func_1($a, $b, $c)
    {
        if ($a) {
            return $b;
        }
        return $c;
    }
    public function func_2($a, $b, $c)
    {
        if ($a) {
            return $b;
        }
        return $c;
    }

    static protected function func_3($a, $b, $c)
    {
        if ($a) {
            return $b;
        }
        return $c;
    }

    private function func_4($a, $b, $c) {
        if ($a) {
            return $b;
        }
        return $c;
    }


    // [FOLDED]: Methods w/ docblock
    /**
     * Docblock func_5
     *
     * multi
     * line comment
     *
     * @param mixed $a comment a
     * @param mixed $b comment b
     * @param mixed $c comment c
     * @return void comment return value
     */
    public static function func_5($a, $b, $c)
    {
        if ($a) {
            return $b;
        }
        return $c;
    }

    /**
     * Docblock func_6
     *
     * separated by empty line from function definition
     *
     * @param mixed $a comment a
     * @param mixed $b comment b
     * @param mixed $c comment c
     * @return void comment return value
     */

    public function func_6($a, $b, $c)
    {
        if ($a) {
            return $b;
        }
        return $c;
    }

    /** @return string single line comment */
    static protected function func_7()
    {
        return null;
    }

    /**
     * Docblock func_8
     *
     * Containing /* inside comment  (Needs fixing, see #9)
     *
     * @return void comment return value
     */
    private function func_8() {
        return 'dummy';
    }

}

// [NOT FOLDED]: abstract class header w/ docblock
/** single line class comment */
abstract class Demo3
{
    // [NOT FOLDED]: Abstract methods w/o docblock
    abstract public function f1();
    abstract protected function f2();
    abstract private function f3();

    // [FOLDED]: Abstract methods w/ docblock
    /**
     * Docblock
     * f4
     *
     * @return void
     */
    abstract public function f4();
    /**
     * @return void returns foo
     */
    abstract protected function f5();
    /** @return void single line docblock */
    abstract private function f6();
}

// [FOLDED]: Custom folds marked with 3 x {
// Fold starts {{{ here
// some line
$a = 5;
if ($a = 5) {
    echo "5";
}
// Fold ends }}} here

