# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48` or any other legacy .NET Framework moniker unless that is intentional for multi-targeting.

### 2. Restore and Build Locally
Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Review the output for any warnings that may indicate deprecated APIs or packages that could cause runtime issues.

### 3. Run Existing Tests
If the solution contains test projects, execute them to verify runtime behavior:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and address them before proceeding.

### 4. Check NuGet Package Compatibility
Open each `.csproj` file and review the `<PackageReference>` entries. For any package that was present in the original project, confirm the referenced version supports the new target framework by checking [nuget.org](https://www.nuget.org). Replace or update any packages that only support .NET Framework.

### 5. Review Removed or Changed APIs
Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` tooling to identify any API usage that may have changed behavior between .NET Framework and modern .NET, even if it compiles without errors.

### 6. Validate Platform-Specific Code
Search the codebase for any usage of the following, which may compile but fail at runtime on non-Windows platforms:

- `System.Windows.Forms` or `System.Drawing` (requires additional packages or Windows)
- `Registry` access via `Microsoft.Win32`
- COM interop or P/Invoke calls
- `AppDomain.CreateDomain` (not supported in .NET Core and later)

### 7. Run the Application
Execute the application directly to confirm expected runtime behavior:

```bash
dotnet run --project <YourMainProject>.csproj --configuration Release
```

Step through the primary workflows and confirm outputs match the expected behavior from the legacy version.

### 8. Publish the Application
Once validation is complete, publish a self-contained or framework-dependent release build:

**Framework-dependent:**
```bash
dotnet publish -c Release -o ./publish
```

**Self-contained (example for Windows x64):**
```bash
dotnet publish -c Release -r win-x64 --self-contained true -o ./publish
```

Verify the contents of the `./publish` folder and confirm the application runs correctly from that output directory.