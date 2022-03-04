insert into results
select 	1 id,(select max(cb) mb from (select book_ref, count(passenger_id) cb from bookings b join tickets t using(book_ref) group by book_ref) f)::text res
union all
select 2 id, (	select sum(cp)
				from (
						select cb,count(book_ref) cp, avg(cb) over () ab
						from (
								select 	book_ref,
										count(passenger_id)  cb
								from bookings b
								join tickets t using(book_ref)
								group by book_ref
						) f
						group by cb
					) t
				where cb>ab
				)::text res
union all
select 3 id, (with tt as (
				select book_ref
				from (
						select 	book_ref,
								count(passenger_id)  cb
						from bookings b
						join tickets t using(book_ref)
						group by book_ref
					) f
				where cb = (select max(cb) mb from (select book_ref, count(passenger_id) cb from bookings b join tickets t using(book_ref) group by book_ref) f)
				group by book_ref
				)
				,rt as (
				select book_ref, passenger_id
				from (
						select 	book_ref,
								cast(cast(row_number() over (partition by book_ref order by passenger_id) as text)||regexp_replace(passenger_id, '\D+', '', 'g') as float) passenger_id
						from bookings b
						join tickets t using(book_ref)
						join tt using(book_ref)
						order by 2
					) r
				)

				select count(distinct book_ref) rep
				from (
				select a.book_ref ,count(1)
				from rt a
				join rt b using(passenger_id)
				group by a.book_ref
				having count(1) >5) f)::text
union all
select * from (
select 4 id, book_ref||'|'||passenger_id||'|'||passenger_name||'|'||contact_data res
from (select 	book_ref,
			passenger_id,
			passenger_name,
			contact_data,
			count(1) over (partition by book_ref) cp
	from bookings b
	join tickets t using(book_ref)
	) w
where cp = 3
order by book_ref,passenger_id, passenger_name, contact_data) r
union all
select 5 id, (select max(fl)
				from (
					select book_ref ,count(distinct flight_id) fl
					from bookings b
					join tickets t using(book_ref)
					join ticket_flights tf using(ticket_no)
					join flights f2 using(flight_id)
					where status != 'Cancelled'
					group by book_ref
				) f)::text res
union all
select 6 id, (select max(fl)
from (
	select book_ref,passenger_id,count(distinct flight_id) fl
	from bookings b
	join tickets t using(book_ref)
	join ticket_flights tf using(ticket_no)
	join flights f2 using(flight_id)
	where status != 'Cancelled'
	group by book_ref,passenger_id
) f)::text
union all
select 7 id, (select max(fl)
from (
	select passenger_id,count(flight_id) fl
	from bookings b
	join tickets t using(book_ref)
	join ticket_flights tf using(ticket_no)
	join flights f2 using(flight_id)
	where status != 'Cancelled'
	group by passenger_id
) f)::text
union all
select 8 id, passenger_id||'|'||passenger_name||'|'||contact_data||'|'||amt
from (
	select f.*, row_number() over (order by amt) rn
	from (
		select passenger_id, passenger_name, contact_data,sum(amount) amt
		from bookings b
		join tickets t using(book_ref)
		join ticket_flights tf using(ticket_no)
		join flights f2 using(flight_id)
		where status != 'Cancelled'
		group by passenger_id, passenger_name, contact_data

	) f
)s
where rn = 1
union all
select 9 id, passenger_id||'|'||passenger_name||'|'||contact_data||'|'||dur
from (
	select f.*, row_number() over (order by dur desc) rn
	from (
		select  passenger_id, passenger_name, contact_data,sum(duration) dur
		from routes r
		join flights f2 using(flight_no)
		join ticket_flights tf using(flight_id)
		join tickets t using(ticket_no)
		group by passenger_id, passenger_name, contact_data
	) f
)s
where rn = 1
union all
select * from (
select 10 id,  city
from (
	select city::json->>'ru' city,count(1)
	from airports_data ad
	group by 1
	having count(1)>1
) f order by 2) d
union all
select * from (
with tt as (
select departure_city city, count( distinct arrival_city) count_city_out
from routes r
group by departure_city)
select 11 id, city
from tt
where count_city_out = (select min(count_city_out) from tt)
order by 2) d
union all
select * from (
with tt as (
select 	a.city::json->>'ru' city1,a.rn rn1, b.city::json->>'ru' city2,b.rn rn2
from 	(select city, row_number() over (order by city) rn from airports_data) a,
		(select city, row_number() over (order by city) rn from airports_data) b
where a.city::json->>'ru' != b.city::json->>'ru'
	)
select distinct 12 id,case when rn1<rn2 then city1||'|'||city2 else city2||'|'||city1 end res
from (
select tt.*
from tt
left join (select distinct departure_city, arrival_city from routes r) f
	on tt.city1 = f.departure_city and tt.city2 = f.arrival_city
left join (select distinct departure_city, arrival_city from routes r) r
	on tt.city2 = r.departure_city and tt.city1 = r.arrival_city
where r.departure_city is null and f.departure_city is null
) d
order by 2) f
union all
select * from (
select distinct 13 id, r.arrival_city
from routes r
left join (select arrival_city from routes where departure_city = 'Москва') f on f.arrival_city = r.arrival_city
where f.arrival_city is null and r.arrival_city != 'Москва'
order by 2) f
union all
select * from
(with tt as (
select model, count(1) cnt
from flights_v fv
join aircrafts a using(aircraft_code)
where status != 'Cancelled'
group by model)
select 14 id, model
from tt
where cnt = (select max(cnt) from tt)) f
union all
select * from
(with tt as (
select model, count(passenger_id) cnt
from flights_v fv
join aircrafts a using(aircraft_code)
join ticket_flights tf using(flight_id)
join tickets tf2 using(ticket_no)
where status != 'Cancelled'
group by model)
select 15 id, model
from tt
where cnt = (select max(cnt) from tt)) d
union all
select 16 id,
		round(sum(extract(epoch from actual_duration)/60 -
		extract(epoch from (fv.scheduled_arrival -fv.scheduled_departure))/60))::text min
from flights_v fv
where status not in ('Cancelled','Scheduled','On Time', 'Delayed')
union all
select * from (
select distinct 17 id,arrival_city
from flights_v fv
where substring(actual_departure::text,1,10)= '2016-09-13'::text and departure_city ='Санкт-Петербург'
order by 2) r
union all
select * from (
with tt as (
select flight_no, sum(amount) amt
from flights_v fv
join ticket_flights tf using(flight_id)
group by flight_no)

select 18 id, flight_no res
from tt
where amt = (select max(amt) from tt)
)d
union all
select * from (
with tt as (
select substring(actual_departure::text,1,10) dd, count(1) cnt
from flights_v fv
where actual_departure is not null and status = 'Arrived'
group by 1
)

select 19 id, dd res
from tt
where cnt = (select min(cnt) from tt))r
union all
select * from (
with tt as (
select substring(actual_departure::text,1,10) dd, count(1) cnt
from flights_v fv
where substring(actual_departure::text,1,7) = '2016-09'
	and status in('Arrived','Departed')
	and departure_city = 'Москва'
group by 1
)

select 20 id, avg(cnt)::text res
from tt ) r
union all
select * from (
with tt as (
select departure_city , avg(extract(epoch from actual_duration)/60/60::float) hh
from flights_v fv
where status ='Arrived'
group by 1)
,rt as (
select 21 id, departure_city res
from tt
order by hh desc
limit  5)

select *
from rt
order by 2) r;
