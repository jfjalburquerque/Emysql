%% Copyright (c) 2009-2013
%% Manuel Rubio <manuel@bosqueviejo.net>
%% Bill Warnecke <bill@rupture.com>
%% Jacob Vorreuter <jacob.vorreuter@gmail.com>
%% Henning Diedrich <hd2010@eonblast.com>
%% Eonblast Corporation <http://www.eonblast.com>
%%
%% Permission is  hereby  granted,  free of charge,  to any person
%% obtaining  a copy of this software and associated documentation
%% files (the "Software"),to deal in the Software without restric-
%% tion,  including  without  limitation the rights to use,  copy,
%% modify, merge,  publish,  distribute,  sublicense,  and/or sell
%% copies  of the  Software,  and to  permit  persons to  whom the
%% Software  is  furnished  to do  so,  subject  to the  following
%% conditions:
%%
%% The above  copyright notice and this permission notice shall be
%% included in all copies or substantial portions of the Software.
%%
%% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
%% EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
%% OF  MERCHANTABILITY,  FITNESS  FOR  A  PARTICULAR  PURPOSE  AND
%% NONINFRINGEMENT. IN  NO  EVENT  SHALL  THE AUTHORS OR COPYRIGHT
%% HOLDERS  BE  LIABLE FOR  ANY CLAIM, DAMAGES OR OTHER LIABILITY,
%% WHETHER IN AN ACTION OF CONTRACT,  TORT  OR OTHERWISE,  ARISING
%% FROM,  OUT OF OR IN CONNECTION WITH THE SOFTWARE  OR THE USE OR
%% OTHER DEALINGS IN THE SOFTWARE.

-module(emysql_metrics).

-export([
    init/0,
    notify_lock/0,
    notify_release/0,
    notify_abort/0,
    notify_wait/0
]).

-define(SLIDE_TIME, 900). %% 15 minutes

-spec init() -> ok.

init() ->
    Metrics = [
        <<"emysqlLocks">>, <<"emysqlReleases">>, 
        <<"emysqlAborts">>, <<"emysqlWaits">>
    ],
    [ folsom_metrics:new_spiral(Metric) || Metric <- Metrics ],
    folsom_metrics:new_histogram(<<"emysqlConnUsage">>, slide, ?SLIDE_TIME),
    folsom_metrics:new_counter(<<"emysqlConns">>),
    ok.

-type notify_return() ::
    ok | {error, Name :: atom(), nonexistent_metric} |
    {error, Type :: atom(), unsupported_metric_type}.


-spec notify_lock() -> notify_return().

notify_lock() -> 
    Active = folsom_metrics_counter:inc(<<"emysqlConns">>), 
    folsom_metrics:notify(<<"emysqlConnUsage">>, Active),
    notify(<<"emysqlLocks">>).

-spec notify_release() -> notify_return().

notify_release() -> 
    Active = folsom_metrics_counter:dec(<<"emysqlConns">>), 
    folsom_metrics:notify(<<"emysqlConnUsage">>, Active),
    notify(<<"emysqlReleases">>).

-spec notify_abort() -> notify_return().

notify_abort() -> notify(<<"emysqlAborts">>).

-spec notify_wait() -> notify_return().

notify_wait() -> notify(<<"emysqlWaits">>).

-spec notify(Metric :: binary()) -> notify_return().

notify(Metric) ->
    folsom_metrics:notify({Metric, 1}).

-spec notify(Metric :: binary(), Value :: integer()) -> notify_return().

notify(Metric, Value) ->
    folsom_metrics:notify({Metric, Value}).
