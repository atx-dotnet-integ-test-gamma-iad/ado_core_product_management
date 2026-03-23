# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

### 2. Restore NuGet Packages
Run the following command from the solution root to ensure all dependencies are restored cleanly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated or unlisted packages and update them if necessary using:

```bash
dotnet list package --outdated
dotnet add package <PackageName>
```

### 3. Build the Solution
Perform a full build to confirm there are no compilation issues:

```bash
dotnet build --configuration Release
```

### 4. Run Existing Tests
If the solution contains test projects, execute the test suite to verify runtime behavior has not changed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as they may indicate behavioral differences between the legacy .NET Framework runtime and the new cross-platform .NET runtime.

### 5. Check for Runtime-Specific API Usage
Even when a project builds successfully, certain APIs behave differently or are unavailable at runtime on non-Windows platforms. Review the code for usage of:

- `System.Windows.Forms` or `System.Web` (not available cross-platform without specific compatibility packages)
- Windows Registry access (`Microsoft.Win32.Registry`)
- Platform-specific file path assumptions (e.g., hardcoded backslashes)
- `AppDomain` APIs that have been restricted in modern .NET

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` tooling to identify these issues.

### 6. Run the Application
Execute the application directly and exercise its primary workflows to confirm functional correctness:

```bash
dotnet run --project ./AdoCore/AdoCore.csproj --configuration Release
```

### 7. Review Configuration Files
Ensure any `app.config` or `web.config` files have been migrated to `appsettings.json` or environment-based configuration where applicable. The legacy XML-based configuration system has limited support in modern .NET.

### 8. Publish the Application
Once validation is complete, publish the application to produce a deployable output:

```bash
dotnet publish --configuration Release --output ./publish
```

Review the contents of the `./publish` directory to confirm all required files and dependencies are present.