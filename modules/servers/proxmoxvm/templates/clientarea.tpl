<div class="panel panel-default">
    <div class="panel-heading">
        <h3 class="panel-title">VM Information</h3>
    </div>
    <div class="panel-body">
        <div class="row">
            <div class="col-md-6">
                <table class="table table-striped">
                    <tr>
                        <td><strong>VM ID:</strong></td>
                        <td>{$vmid}</td>
                    </tr>
                    <tr>
                        <td><strong>Node:</strong></td>
                        <td>{$node}</td>
                    </tr>
                    <tr>
                        <td><strong>Status:</strong></td>
                        <td>
                            {if $status == 'running'}
                                <span class="label label-success">Running</span>
                            {elseif $status == 'stopped'}
                                <span class="label label-danger">Stopped</span>
                            {else}
                                <span class="label label-warning">{$status}</span>
                            {/if}
                        </td>
                    </tr>
                    <tr>
                        <td><strong>IP Address:</strong></td>
                        <td>{$ip}</td>
                    </tr>
                </table>
            </div>
            <div class="col-md-6">
                <table class="table table-striped">
                    <tr>
                        <td><strong>CPU Cores:</strong></td>
                        <td>{$cores}</td>
                    </tr>
                    <tr>
                        <td><strong>Memory:</strong></td>
                        <td>{$memory} MB</td>
                    </tr>
                    <tr>
                        <td><strong>Disk Space:</strong></td>
                        <td>{$disk} GB</td>
                    </tr>
                    <tr>
                        <td><strong>Root Password:</strong></td>
                        <td>
                            <span class="password-hidden">••••••••</span>
                            <span class="password-shown" style="display:none;">{$password}</span>
                            <button type="button" class="btn btn-xs btn-default toggle-password">
                                <i class="fa fa-eye"></i>
                            </button>
                        </td>
                    </tr>
                </table>
            </div>
        </div>
    </div>
</div>

<div class="panel panel-default">
    <div class="panel-heading">
        <h3 class="panel-title">VM Controls</h3>
    </div>
    <div class="panel-body">
        <div class="row">
            <div class="col-md-12">
                <form method="post" action="clientarea.php?action=productdetails">
                    <input type="hidden" name="id" value="{$serviceid}" />
                    <input type="hidden" name="modop" value="custom" />
                    
                    <div class="btn-group" role="group">
                        <button type="submit" name="a" value="ClientStartVM" class="btn btn-success" {if $status == 'running'}disabled{/if}>
                            <i class="fa fa-play"></i> Start
                        </button>
                        <button type="submit" name="a" value="ClientStopVM" class="btn btn-danger" {if $status == 'stopped'}disabled{/if}>
                            <i class="fa fa-stop"></i> Stop
                        </button>
                        <button type="submit" name="a" value="ClientRestartVM" class="btn btn-warning" {if $status != 'running'}disabled{/if}>
                            <i class="fa fa-refresh"></i> Restart
                        </button>
                    </div>
                    
                    <a href="{$systemurl}clientarea.php?action=productdetails&id={$serviceid}&dosinglesignon=1" class="btn btn-primary" target="_blank">
                        <i class="fa fa-desktop"></i> Open Console
                    </a>
                </form>
            </div>
        </div>
    </div>
</div>

<script>
$(document).ready(function() {
    $('.toggle-password').click(function() {
        var passwordHidden = $(this).siblings('.password-hidden');
        var passwordShown = $(this).siblings('.password-shown');
        var icon = $(this).find('i');
        
        if (passwordHidden.is(':visible')) {
            passwordHidden.hide();
            passwordShown.show();
            icon.removeClass('fa-eye').addClass('fa-eye-slash');
        } else {
            passwordHidden.show();
            passwordShown.hide();
            icon.removeClass('fa-eye-slash').addClass('fa-eye');
        }
    });
});
</script>

<style>
.password-hidden, .password-shown {
    font-family: monospace;
}
.toggle-password {
    margin-left: 10px;
}
</style>
