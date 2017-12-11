<?php
include_once "bdSetting.php";
$CONN = sqlsrv_connect($SERVER_NAME, $CONNECTION_INFO);

if(!$CONN){
    die( print_r( sqlsrv_errors(), true));
}

$sql = "
SELECT
  fullName,
  lastCountRows,
  lastLoadDtm,
  nowCountRows,
  nowLoadDtm,
  diffPerc,
  nowPerc
FROM TOOLS.cft.vVerification
order by nowPerc
";
$st = sqlsrv_query($CONN, $sql);
if( $st === false ) {
     die( print_r( sqlsrv_errors(), true));
}

while($row = sqlsrv_fetch_array($st, SQLSRV_FETCH_ASSOC))
{
    $result[]= array(
        'fullName'      =>  $row['fullName'],
        'lastCountRows' =>  $row['lastCountRows'],
        'lastLoadDtm'   =>  $row['lastLoadDtm']->format('d.m.Y H:m:s'),
        'nowCountRows'  =>  $row['nowCountRows'],
        'nowLoadDtm'    =>  $row['nowLoadDtm']->format('d.m.Y H:m:s'),
        'diffPerc'      =>  $row['diffPerc'],
        'nowPerc'       =>  $row['nowPerc']
    );
};

$table = '<ul>';
$countError = 0;
for($i = 0; $i < count($result); $i++){
    $classStyle = '';
    if($result[$i]['nowPerc'] <= $result[$i]['diffPerc']){
        $classStyle = 'verify-error';
        $countError++;
    }
    $table .= '<li class="'.$classStyle.'">
        <div class="verify-table-block">Объект: '.$result[$i]['fullName'].'</div>
        <table class="verify-table" id="verify_table_'.$i.'">
            <tr>
                <th></th>
                <th>Предыдущее измерение</th>
                <th>Последние измерение</th>
                <th>Процент</th>
            </tr>
            <tr>
                <td class="verify-caption-row">Дата и время:</td>
                <td>'.$result[$i]['lastLoadDtm'].'</td>
                <td>'.$result[$i]['nowLoadDtm'].'</td>
                <td rowspan="3">'.number_format($result[$i]['nowPerc'],3).'</td>
            </tr>
            <tr>
                <td class="verify-caption-row">Кол-во строк:</td>
                <td>'.$result[$i]['lastCountRows'].'</td>
                <td>'.$result[$i]['nowCountRows'].'</td>
            </tr>
        </table>
        <table class="verify-table-small" id="verify_table_small_'.$i.'">
            <tr>
                <td class="verify-caption-row">Кол-во строк(было / стало):</td>
                <td>'.$result[$i]['lastCountRows'].'</td>
                <td>/</td>
                <td>'.$result[$i]['nowCountRows'].'</td>
            </tr>
        </table>
        </li>';
}
$table .= "</ul>";

$info = '<div class="verify-info-result">Всего объектов проверено '.count($result);
$info .= ' из них с предупреждениями <strong>'.$countError.'</strong></div>';
echo $info.$table;

sqlsrv_close($CONN);
?>