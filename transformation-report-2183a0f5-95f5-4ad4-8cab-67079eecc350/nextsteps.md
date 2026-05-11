# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Review Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version (e.g., `net8.0` or `net9.0`). Example:

```xml
<PropertyGroup>
  <TargetFramework>net8.0</TargetFramework>
</PropertyGroup>
```

### 2. Restore and Build Locally
Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Confirm there are no warnings that could indicate compatibility issues, such as deprecated APIs or platform-specific code paths.

### 3. Run Existing Tests
If the solution contains test projects, execute them to verify runtime behavior has not regressed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and determine whether they are caused by behavioral differences between the legacy .NET Framework and the new cross-platform .NET runtime.

### 4. Check for Platform-Specific API Usage
Use the .NET Compatibility Analyzer or review the code manually for APIs that may have been available in .NET Framework but are absent or behave differently in cross-platform .NET. Common areas to check include:

- `System.Web` references (not available in .NET Core/.NET 5+)
- Windows Registry access (`Microsoft.Win32.Registry`)
- `AppDomain` usage
- Remoting or binary serialization (`BinaryFormatter`)
- WCF server-side components

### 5. Verify NuGet Package Compatibility
Open the `.csproj` files and review all `<PackageReference>` entries. Ensure each package supports the target framework. You can verify this on [nuget.org](https://www.nuget.org) by checking the package's supported frameworks tab.

### 6. Test on Target Platforms
If cross-platform support (Linux, macOS) is a goal, run the application on each intended platform to surface any OS-specific runtime issues that would not appear during a Windows build.

```bash
dotnet run --configuration Release
```

### 7. Publish the Application
Once validation is complete, publish the application using the appropriate runtime identifier for your deployment target:

**Framework-dependent (requires .NET runtime installed on host):**
```bash
dotnet publish --configuration Release --output ./publish
```

**Self-contained (bundles the runtime):**
```bash
dotnet publish --configuration Release --self-contained true --runtime linux-x64 --output ./publish
```

Replace `linux-x64` with the appropriate runtime identifier (e.g., `win-x64`, `osx-x64`, `osx-arm64`) as needed.

Review the contents of the `./publish` folder and deploy to the target environment according to your hosting setup (e.g., IIS, Kestrel, systemd service, or direct execution).