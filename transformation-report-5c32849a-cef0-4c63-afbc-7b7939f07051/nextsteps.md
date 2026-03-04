# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Restore Dependencies

Run the following command from the solution root to ensure all NuGet packages are properly restored:

```bash
dotnet restore
```

Review the output for any warnings related to package compatibility or deprecated packages targeting older frameworks.

## 2. Build the Solution

Perform a full solution build to confirm the error-free state is consistent across all configurations:

```bash
dotnet build --configuration Debug
dotnet build --configuration Release
```

Address any warnings that surface, particularly those related to nullable reference types or obsolete APIs, as these can indicate latent issues.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify runtime behavior has not changed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review test output carefully. A successful build does not guarantee correct runtime behavior after a framework migration.

## 4. Verify Target Framework

Open each `.csproj` file and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48` or other legacy framework monikers unless intentional multi-targeting is in place.

## 5. Check for Platform-Specific API Usage

Review the code for any APIs that were available in .NET Framework but have limited or no support in cross-platform .NET, including:

- `System.Web` namespaces
- Windows Registry access (`Microsoft.Win32.Registry`)
- `AppDomain` usage beyond what is supported
- WCF server-side components
- `System.Drawing` on non-Windows platforms

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` tooling to identify remaining compatibility concerns.

## 6. Test on Target Platforms

If cross-platform support is a goal, run and validate the application on each intended operating system (Windows, Linux, macOS) to surface any platform-specific runtime issues that would not appear during a Windows-only build.

```bash
dotnet run --configuration Release
```

## 7. Review Configuration Files

Ensure that any `app.config` or `web.config` files have been appropriately migrated to `appsettings.json` or environment-based configuration using `Microsoft.Extensions.Configuration`. Legacy XML-based configuration is not natively supported in cross-platform .NET.

## 8. Publish the Application

Once validation is complete, publish the application for your target environment:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true
```

Replace `linux-x64` with your intended runtime identifier (e.g., `win-x64`, `osx-x64`). Use `--self-contained false` if you expect the .NET runtime to be pre-installed on the target machine.