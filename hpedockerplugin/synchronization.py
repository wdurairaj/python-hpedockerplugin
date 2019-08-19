import inspect
import json

from oslo_log import log as logging

import hpedockerplugin.exception as exception
import time

LOG = logging.getLogger(__name__)


def __synchronized(lock_type, lock_name, f, *a, **k):
    call_args = inspect.getcallargs(f, *a, **k)
    call_args['f_name'] = f.__name__
    lck_name = lock_name.format(**call_args)
    lock_acquired = False
    self = call_args['self']
    lock = self._etcd.get_lock(lock_type)
    try_num = 0
    while try_num <= 6:
        try:
            LOG.info('RETRY : Lock acquire call %s ' % str(try_num))
            lock.try_lock_name(lck_name)
            lock_acquired = True
            LOG.info('Lock acquired: [caller=%s, lock-name=%s]'
                     % (f.__name__, lck_name))
            return f(*a, **k)
        except exception.HPEPluginLockFailed:
            LOG.exception('Lock acquire failed: [caller=%(caller)s, '
                          'lock-name=%(name)s]',
                          {'caller': f.__name__,
                           'name': lck_name})
            try_num = try_num + 1
            if try_num < 6:
                if call_args['f_name'] == "mount_volume" \
                        or call_args['f_name'] == "unmount_volume":
                    LOG.info('RETRY : sleep on retry num : %s' % str(try_num))
                    time.sleep(30)
                    continue
            response = json.dumps({u"Err": ''})
            return response
        finally:
            if lock_acquired:
                try:
                    lock.try_unlock_name(lck_name)
                    LOG.info('Lock released: [caller=%s, lock-name=%s]' %
                             (f.__name__, lck_name))
                except exception.HPEPluginUnlockFailed:
                    LOG.exception('Lock release failed: [caller=%(caller)s'
                                  ', lock-name=%(name)s]',
                                  {'caller': f.__name__,
                                   'name': lck_name})


def synchronized_volume(lock_name):
    def _synchronized(f):
        def _wrapped(*a, **k):
            return __synchronized('VOL', lock_name, f, *a, **k)
        return _wrapped
    return _synchronized


def synchronized_rcg(lock_name):
    def _synchronized(f):
        def _wrapped(*a, **k):
            return __synchronized('RCG', lock_name, f, *a, **k)
        return _wrapped
    return _synchronized
