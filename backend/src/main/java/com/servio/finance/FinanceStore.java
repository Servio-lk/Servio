package com.servio.finance;
import lombok.RequiredArgsConstructor;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;
import java.math.BigDecimal;
import java.util.*;

@Repository
@RequiredArgsConstructor
public class FinanceStore {
    private final JdbcTemplate jdbc;
    public List<Map<String,Object>> rows(String sql,Object...args) { return jdbc.queryForList(sql,args); }
    public Map<String,Object> one(String sql,Object...args) {
        var rows=rows(sql,args);
        if(rows.isEmpty()) throw new IllegalArgumentException("Record not found");
        return rows.get(0);
    }
    public int update(String sql,Object...args) { return jdbc.update(sql,args); }
    public long insert(String sql,Object...args) {
        var keys=new org.springframework.jdbc.support.GeneratedKeyHolder();
        String statement=sql.replaceFirst("(?i)\\s+RETURNING\\s+id\\s*$","");
        jdbc.update(connection->{
            var prepared=connection.prepareStatement(statement,new String[]{"id"});
            for(int i=0;i<args.length;i++) prepared.setObject(i+1,args[i]);
            return prepared;
        },keys);
        Number key=keys.getKey();
        if(key==null) throw new IllegalStateException("Insert did not return an ID");
        return key.longValue();
    }
    public BigDecimal amount(String sql,Object...args) {
        Object value=one(sql,args).values().iterator().next();
        return value==null ? BigDecimal.ZERO : new BigDecimal(value.toString());
    }
    public void audit(String type,long id,String action,String actor,String details) {
        update("INSERT INTO finance_audit(resource_type,resource_id,action,actor,details) VALUES(?,?,?,?,?)",type,id,action,actor,details);
    }
    public static long id(Map<String,Object> row,String key) { return ((Number)row.get(key)).longValue(); }
    public static BigDecimal decimal(Map<String,Object> row,String key) {
        Object v=row.get(key); return v==null ? BigDecimal.ZERO : new BigDecimal(v.toString());
    }
}
