
--https://dbatman.blog/2018/05/18/asm-disk-size-imbalance-query/

SELECT file_num, MAX(extent_count) max_disk_extents, MIN(extent_count)
min_disk_extents
, MAX(extent_count) - MIN(extent_count) disk_extents_imbalance
FROM (SELECT number_kffxp file_num, disk_kffxp disk_num, COUNT(xnum_kffxp)
extent_count
FROM x$kffxp
WHERE group_kffxp = 1
AND disk_kffxp != 65534
GROUP BY number_kffxp, disk_kffxp
ORDER BY number_kffxp, disk_kffxp)
GROUP BY file_num
HAVING MAX(extent_count) - MIN(extent_count) > 5
ORDER BY disk_extents_imbalance DESC;
