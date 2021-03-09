**Aricultural Price Final Report**
** Group 3 b06607058 邴國榮 b07607001 鄭鈞瀚 b07607015 楊皓閔 b07607027 詹勳亞**
** Topic: little tomato**

***************************
**      monthly Data     **
*************************** 
/*Import data and generate time variance (name it date)*/
/*Please change the path of data when download, which it may be in downloads or other place after download*/
import excel "C:\Users\user\Desktop\組3 - 小番茄.xls", sheet("Sheet1") cellrange(A1:B241) firstrow
generate date = tm(2000m1)+_n-1
format date %tm
/*Get "sts15_2.pkg" (if already had, pass this one)*/
findit kpss
/*Set time variance*/
tsset date
/*Set log price and name it log_P1*/
gen log_P1 = log(ave_price_1)
/*Draw the picture between date and log_P1*/
tsline log_P1, name(unresi)
/*Description statistic about log_P1*/
summarize ave_price_1 log_P1
graph box log_P1
twoway histogram log_P1 || kdensity log_P1


/*Unit root test for log_P1*/
/*D-F Test*/
dfuller log_P1 if date < tm(2017m1), regress
dfuller log_P1 if date < tm(2017m1), regress trend
/*P-P Test*/
pperron log_P1 if date < tm(2017m1) , regress
pperron log_P1 if date < tm(2017m1) , regress trend
/*KPSS Test*/
kpss log_P1 if date < tm(2017m1), maxlag(8)
kpss log_P1 if date < tm(2017m1), maxlag(8) notrend
/*Result: log_P1 has no unit root but have deterministic trend, which is not stationary. Thus we need to detrend log_P1*/

/*Detrend*/
/*By making resisuals of log_P1*/
reg log_P1 date
predict r_log_P1, residuals
tsline r_log_P1, name(resi)
graph combine unresi resi, note("95%C.I.")
/*Try and Error*/
dfgls r_log_P1 if date < tm(2017m1)
dfuller r_log_P1 if date < tm(2017m1), regress
dfuller r_log_P1 if date < tm(2017m1), regress trend
pperron r_log_P1 if date < tm(2017m1), regress trend
pperron r_log_P1 if date < tm(2017m1), regress
kpss r_log_P1 if date < tm(2017m1), maxlag(8)
kpss r_log_P1 if date < tm(2017m1), maxlag(8) notrend
/*Result: r_log_P1 doesn't have unit root and deterministic trend, which is stationary.*/

/*Drow ACF and PACF of r_log_P1*/
ac r_log_P1 if date < tm(2017m1), name(dac)
pac r_log_P1 if date < tm(2017m1), name(dpac)
graph combine dac dpac, note("95%C.I.")
/*After comparison, choose AR(4) MA(2) to deside the model*/

/*ARIMA*/
qui arima r_log_P1 if date < tm(2017m1), arima(0,0,0) nolog noconstant 
estat ic
qui arima r_log_P1 if date < tm(2017m1), arima(0,0,1) nolog noconstant
estat ic
qui arima r_log_P1 if date < tm(2017m1), arima(0,0,2) nolog noconstant
estat ic
qui arima r_log_P1 if date < tm(2017m1), arima(1,0,0) nolog noconstant 
estat ic
qui arima r_log_P1 if date < tm(2017m1), arima(1,0,1) nolog noconstant
estat ic
qui arima r_log_P1 if date < tm(2017m1), arima(1,0,2) nolog noconstant 
estat ic
qui arima r_log_P1 if date < tm(2017m1), arima(2,0,0) nolog noconstant
estat ic
qui arima r_log_P1 if date < tm(2017m1), arima(2,0,1) nolog noconstant
estat ic
qui arima r_log_P1 if date < tm(2017m1), arima(2,0,2) nolog noconstant 
estat ic
qui arima r_log_P1 if date < tm(2017m1), arima(3,0,0) nolog noconstant
estat ic
qui arima r_log_P1 if date < tm(2017m1), arima(3,0,1) nolog noconstant 
estat ic
qui arima r_log_P1 if date < tm(2017m1), arima(3,0,2) nolog noconstant
estat ic
qui arima r_log_P1 if date < tm(2017m1), arima(4,0,0) nolog noconstant
estat ic
qui arima r_log_P1 if date < tm(2017m1), arima(4,0,1) nolog noconstant 
estat ic
qui arima r_log_P1 if date < tm(2017m1), arima(4,0,2) nolog noconstant
estat ic
/*Comparing AIC & BIC, choose ARIMA(2,0,1) which has smallest AIC & BIC*/
arima r_log_P1 if date < tm(2017m1), arima(2,0,1) nolog noconstant

/*Predict residuals of log_P1 by "one-step-ahead" and "t0" */
predict one_ahead
predict one_res, residual
predict t0, t0(tm(2017m1)) 
predict t0_res, t0(tm(2017m1)) residual
/*Generate the absolute value of two residuals*/
gen abs_one = abs(one_res)
gen abs_t0 = abs(t0_res)
/*Label the variance*/
label variable one_ahead "one step ahead"
label variable t0 "t0"
label variable one_res "one step ahead residual"
label variable t0_res "t0 residual"
label variable abs_one "abs of one_ahead"
label variable abs_t0 "abs of t0"

/*List three residuals and two fitted value*/
list date r_log_P1 one_ahead t0 in  -45/l
gen byte period = (date >= tm(2017m1))
label define period 1 "out of sample" 0 "in sample"
label value period period
**list mean and sd of predict result, either in-the-sample or out-of-the-sample**
table period,contents(mean r_log_P1 mean one_ahead mean t0) format(%8.3f) row 
table period,contents(sd r_log_P1 sd one_ahead sd t0) format(%8.3f)
table period,contents(mean abs_one sd one_res mean abs_t0 sd  t0_res ) row format(%8.3f)
/*generate the twoway graph*/
twoway (tsline r_log_P1) (tsline one_ahead)
twoway (tsline r_log_P1) (tsline t0)

/*Generate ARMA(2,1) function*/
gen lag1_log_P1 = log_P1[_n-1]
gen lag2_log_P1 = log_P1[_n-2]
gen lag1_r_log_P1 = one_ahead[_n-1]
/*Model log_P1 and generate the graph of log_P1 and predicted value with one-step-ahead*/
reg log_P1 lag1_log_P1 lag2_log_P1 one_ahead lag1_r_log_P1 date, noconstant
predict xb2
twoway (tsline log_P1 ) (tsline xb2)
/*Generate mse and mae*/
reg log_P1 lag1_log_P1 lag2_log_P1 one_ahead lag1_r_log_P1 date, noconstant
predict e,xb
/*MSE*/
/*Average of mse is MSE*/
gen mse = ( log_P1 -e)*( log_P1 -e)
sum mse
label variable mse "mean sum error"
/*MAE*/
/*Average of mae is MAE*/
gen mae = abs( log_P1 -e)
sum mae
label variable mae "mean absolute error"
label variable period "period "
/*The variance of time is rejected in alpha = 5%, it may beacause the model doesn't consider quantity*/

/*Test whether quantity effects price*/
/*Set quantity data, change it into tonnes, and generate log of quantity in tonnes, name it log_t_Q1*/
gen tonnes_Q1 = quantity_1 / 1000
gen log_t_Q1 = log(tonnes_Q1)
/*Find out whether there is missing value in quantity data*/
summarize log_t_Q1
/*Generate plot between log_P1 and log_t_Q1*/
twoway scatter log_P1 log_t_Q1
twoway (tsline log_P1) (tsline log_t_Q1)
/*Generate quantity in date(t-1)*/
gen lag1_log_t_Q1 = log_t_Q1[_n-1]
/*Regress log_P1 and lag1_log_t_Q1 to find their relationship*/
reg log_P1 lag1_log_t_Q1, noconstant
/*Model log_P1 and generate the graph of log_P1 and predicted value, which consider quantity in previous period this time*/
reg log_P1 lag1_log_P1 lag2_log_P1 one_ahead lag1_r_log_P1 lag1_log_t_Q1 date, noconstant
predict xb3
twoway (tsline log_P1 ) (tsline xb3)
/*Generate mse & mae*/
reg log_P1 lag1_log_P1 lag2_log_P1 one_ahead lag1_r_log_P1 lag1_log_t_Q1 date, noconstant
predict e_1,xb
/*MSE*/
/*Average of mse is MSE*/
gen mse_Q1 = ( log_P1 -e_1)*( log_P1 -e_1)
sum mse_Q1
label variable mse "mean sum error"
/*MAE*/
/*Average of mae is MAE*/
gen mae_Q1 = abs( log_P1 -e_1)
sum mae_Q1
label variable mae "mean absolute error"
label variable period "period "
/*None of the variance in the model are rejected this time*/