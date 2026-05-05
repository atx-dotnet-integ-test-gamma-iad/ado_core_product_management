# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended .NET version (e.g., `net8.0` or `net6.0`). Example:

```xml
<PropertyGroup>
  <TargetFramework>net8.0</TargetFramework>
</PropertyGroup>
```

## 2. Restore and Build Locally

Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Review the output for any warnings that may indicate deprecated APIs or packages that could cause runtime issues even if they do not block compilation.

## 3. Review NuGet Package Versions

Open the `.csproj` file and check all `<PackageReference>` entries. Ensure each package:
- Has a version compatible with your target framework.
- Is not a Windows-only package (e.g., packages prefixed with `Microsoft.Windows` or those wrapping Win32 APIs) if cross-platform support is required.

You can check compatibility using the [NuGet Package Explorer](https://www.nuget.org/packages) or by running:

```bash
dotnet list package --outdated
```

## 4. Run Existing Tests

If the solution contains a test project, execute the test suite to verify runtime behavior has not changed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as they may indicate behavioral differences between the legacy .NET Framework runtime and the new .NET runtime.

## 5. Check for Platform-Specific Code

Search the codebase for APIs that are known to behave differently or be unavailable on non-Windows platforms, including:

- `System.Windows.Forms` or `System.Drawing` (requires additional packages on Linux/macOS)
- `Microsoft.Win32` registry access
- `AppDomain.GetCurrentThreadId()`
- P/Invoke calls to Windows-specific DLLs

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` package where applicable.

## 6. Validate Configuration Files

If the project previously used `app.config` or `web.config`, confirm that settings have been migrated to `appsettings.json` or environment variables, as `ConfigurationManager` behavior differs in .NET 6+.

## 7. Perform a Runtime Smoke Test

Run the application directly and exercise its primary functionality:

```bash
dotnet run --project AdoCore.csproj --configuration Release
```

Confirm that database connections, file I/O, and any external service calls behave as expected.

## 8. Publish the Application

Once validation is complete, publish a self-contained or framework-dependent build:

**Framework-dependent:**
```bash
dotnet publish AdoCore.csproj --configuration Release --output ./publish
```

**Self-contained (example for Linux x64):**
```bash
dotnet publish AdoCore.csproj --configuration Release --runtime linux-x64 --self-contained true --output ./publish
```

Review the contents of the `./publish` directory and confirm all required assets are present before deploying to the target environment.